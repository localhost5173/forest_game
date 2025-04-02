extends CharacterBody3D

# Movement settings
@export var land_speed := 5.0
@export var water_speed := 0.1
@export var mouse_sensitivity := 0.1
@export var jump_speed := 5.0
@export var gravity := 9.8
@export var fly_speed := 100.0

# Water physics settings
@export var buoyancy_force := 3.5
@export var water_drag := 1.5
@export var water_angular_drag := 0.8
@export var float_surface_offset := 0.3  # Camera height compensation

# Ambient sounds
@export var min_run_interval := 25.0
@export var max_run_interval := 45.0
@export var running_sound_distance := 12.0

@onready var camera = $Camera3D
@onready var flashlight = $Camera3D/SpotLight3D
@onready var raycast = $Camera3D/RunestoneRayCast
@onready var boss_raycast = $Camera3D/BossRayCast
@onready var tooltip_label = $TooltipLabel 	
@onready var coordinates_label = $Coordinates  # Adjust the path as necessary

@onready var runestone_pickup = preload("res://sounds/runestone_pickup.mp3")
@onready var ambient_music = preload("res://sounds/ambient.mp3")

var current_speed := land_speed
var is_flying := false
var is_swimming := false
var ambient_timer: Timer

# Water overlay
var underwater_overlay: ColorRect
var is_underwater: bool = false
var water_level := -6.0  # Should match your water plane height

var runestone_inventory = { "colossal": true, "magma": true, "water": true }
#var runestone_inventory = {}

var required_runestones = ["magma", "colossal", "water"]
var boss_spawned = false

var saw_boss = false

var ambient_sound_player : AudioStreamPlayer

func has_all_runestones() -> bool:
	return runestone_inventory.has_all(required_runestones)

func collect_runestone(runestone_type: String):
	play_ambient_sound(runestone_pickup, 5)
	runestone_inventory[runestone_type] = true
	print("Runestone inventory", runestone_inventory)
	if runestone_type == "magma":
		$MagmaRunestoneInfo.text = "Magma Runestone: ✅"
	elif  runestone_type == "water":
		$WaterRunestoneInfo.text = "Water Runestone: ✅"
	else:
		$ColossalRunestoneInfo.text = "Colossal Runestone: ✅"
	# Update your HUD here. For example:
	#$HUD/RunestoneIconContainer.update_icons(runestone_inventory)
	print("Collected ", runestone_type, " runestone!")

func set_tooltip(text: String):
	$TooltipLabel.text = text
	$TooltipLabel.visible = text != ""

func clear_tooltip():
	$TooltipLabel.text = ""
	$TooltipLabel.visible = false



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	setup_underwater_overlay()
	setup_ambient_timer()
	current_speed = land_speed
	
	ambient_sound_player = AudioStreamPlayer.new()
	
	add_child(ambient_sound_player)
	ambient_sound_player.stream = load("res://sounds/ambient.mp3")
	ambient_sound_player.volume_db = -10.0
	ambient_sound_player.bus = "Ambient"  # Make sure you have an 'Ambient' bus in Audio settings
	ambient_sound_player.stream.loop = true
	ambient_sound_player.play()

func setup_ambient_timer():
	ambient_timer = Timer.new()
	add_child(ambient_timer)
	ambient_timer.wait_time = randf_range(min_run_interval, max_run_interval)
	ambient_timer.one_shot = true
	ambient_timer.timeout.connect(_on_ambient_timer_timeout)
	ambient_timer.start()

func _on_ambient_timer_timeout():
	print("RUnning sound")
	play_running_sound()
	# Reset timer with new random interval
	ambient_timer.wait_time = randf_range(min_run_interval, max_run_interval)
	ambient_timer.start()

func play_running_sound():
	var behind_direction = -global_transform.basis.z.normalized()
	var random_angle = randf_range(-PI/4, PI/4)
	var sound_direction = behind_direction.rotated(Vector3.UP, random_angle)
	var sound_position = global_position + sound_direction * running_sound_distance
	
	# Add vertical offset and random horizontal variation
	sound_position.y += randf_range(-1.0, 1.0)
	sound_position += Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0))
	
	play_sound_at(load("res://sounds/ambient_running.mp3"), sound_position, 50)
	play_ambient_sound(load("res://sounds/ambient_running.mp3"), 15)

func play_sound_at(sound_file: AudioStream, position: Vector3, volume: float):
	var player = AudioStreamPlayer3D.new()
	add_child(player)
	player.stream = sound_file
	player.transform.origin = position
	player.volume_db = volume
	player.max_distance = 20.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player.play()
	await player.finished
	player.queue_free()

func play_ambient_sound(sound_file: AudioStream, volume_db: float = -10.0):
	var ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	ambient_player.stream = sound_file
	ambient_player.volume_db = volume_db
	ambient_player.bus = "Ambient"  # Make sure you have an 'Ambient' bus in Audio settings
	ambient_player.play()
	return ambient_player  # Return in case you need to stop it later

func setup_underwater_overlay():
	underwater_overlay = ColorRect.new()
	underwater_overlay.color = Color(0.2, 0.6, 1.0, 0.0)
	underwater_overlay.size = Vector2(10000, 10000)
	underwater_overlay.material = ShaderMaterial.new()
	
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float wave_amount = 0.02;
	uniform float wave_speed = 5.0;
	uniform float blur_amount = 0.005;
	
	void fragment() {
		vec2 uv = SCREEN_UV;
		uv.x += sin(TIME * wave_speed + uv.y * 20.0) * wave_amount;
		uv.y += cos(TIME * wave_speed * 0.7 + uv.x * 20.0) * wave_amount;
		vec4 color = vec4(0.0);
		color += texture(SCREEN_TEXTURE, uv + vec2(-blur_amount, -blur_amount)) * 0.5;
		color += texture(SCREEN_TEXTURE, uv + vec2(blur_amount, -blur_amount)) * 0.5;
		color += texture(SCREEN_TEXTURE, uv + vec2(-blur_amount, blur_amount)) * 0.5;
		color += texture(SCREEN_TEXTURE, uv + vec2(blur_amount, blur_amount)) * 0.5;
		COLOR = color;
	}
	"""
	underwater_overlay.material.shader = shader
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(underwater_overlay)
	add_child(canvas_layer)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
		camera.rotate_x(-event.relative.y * mouse_sensitivity * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	if event.is_action_pressed("toggle_flashlight"):
		flashlight.visible = !flashlight.visible
		play_ambient_sound(load("res://sounds/flashlight_toggle.mp3"), 12)
	
	if event.is_action_pressed("fly"):
		is_flying = !is_flying
		
		# When E is pressed, try to collect the runestone
	if event.is_action_pressed("ui_accept"):  # Ensure "ui_accept" is bound to the desired key
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.has_method("get_runestone_type"):
				var runestone_type = collider.get_runestone_type()
				collect_runestone(runestone_type)
				collider.queue_free()  # Remove the runestone from the scene
				clear_tooltip()
			if collider.has_method("spawn_boss") and has_all_runestones():
				ambient_sound_player.stop()
				collider.spawn_boss(self)
				boss_spawned = true
				set_tooltip("")
		
func _process(delta):
	var player_position = transform.origin
	coordinates_label.text = "Coordinates: X=%.2f, Y=%.2f, Z=%.2f" % [player_position.x, player_position.y, player_position.z]
	
	var altars = get_tree().get_nodes_in_group("altar_hitbox")
	for altar in altars:
		var parent = altar.get_parent()  # Get the parent node
		if parent is StaticBody3D or parent is RigidBody3D or parent is Area3D:
			raycast.add_exception(parent)  # Add the parent as an exception
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("get_runestone_type"):
			var runestone_type = collider.get_runestone_type()
			set_tooltip("Press [E] to collect the " + runestone_type + " runestone")
		elif collider and collider.has_method("spawn_boss"):
			if has_all_runestones() and boss_spawned == false:
				set_tooltip("Press [E] to use runestones")
			elif boss_spawned == false:
				set_tooltip("Collect all runestones before coming back!")
		elif collider and collider.has_method("move_towards_player"):
			collider.move_towards_player(global_transform.origin)
		else:
			clear_tooltip()
	else:
		clear_tooltip()
		
	boss_raycast.collision_mask = 1 << 2  # Raycast detects layer 3
	if boss_raycast.is_colliding() and !saw_boss:
		print("Boss raycast hit:", boss_raycast.get_collider())
		var collider = boss_raycast.get_collider()
		if collider and collider.has_method("move_towards_player"):
			collider.move_towards_player(global_transform.origin)
			saw_boss = true


func _physics_process(delta):
	var new_underwater = camera.global_position.y < water_level
	handle_water_transition(new_underwater)
	
	if is_flying:
		handle_flying_movement(delta)
	else:
		if is_underwater:
			handle_underwater_movement(delta)
		else:
			handle_land_movement(delta)
	
	move_and_slide()

func handle_water_transition(underwater: bool):
	if underwater != is_underwater:
		is_underwater = underwater
		is_swimming = underwater
		current_speed = water_speed if underwater else land_speed
		
		var target_alpha = 0.3 if underwater else 0.0
		var tween = create_tween()
		tween.tween_property(underwater_overlay, "color:a", target_alpha, 0.5)

		# Play water splash sounds
		if underwater:
			play_ambient_sound(load("res://sounds/water_splash.mp3"), 10)
			# Start underwater ambient sound
			#play_ambient_sound(load("res://sounds/underwater_loop.ogg"), -15.0)
		else:
			pass


func handle_land_movement(delta):
	var input_dir = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).rotated(Vector3.UP, rotation.y).normalized()
	
	velocity.x = input_dir.x * current_speed
	velocity.z = input_dir.z * current_speed
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed

func handle_underwater_movement(delta):
	var input_dir = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("jump") - Input.get_action_strength("crouch"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).rotated(Vector3.UP, rotation.y).normalized()
	
	# Buoyancy calculations
	var depth = water_level - global_position.y
	if depth > 0:
		velocity.y += buoyancy_force * depth * delta
	
	# Apply water physics
	velocity = velocity.lerp(input_dir * current_speed, water_drag * delta)
	
	# Surface positioning
	if global_position.y > water_level + float_surface_offset - camera.position.y:
		velocity.y *= 0.5
		global_position.y = water_level + float_surface_offset - camera.position.y

func handle_flying_movement(delta):
	var input_dir = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("jump") - Input.get_action_strength("crouch"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).rotated(Vector3.UP, rotation.y).normalized()
	
	velocity = input_dir * fly_speed
