extends CharacterBody3D

@onready var boss_scene = preload("res://scenes/boss.tscn")
@onready var god_is_coming = preload("res://sounds/god_is_coming.mp3")
@onready var god_is_here = preload("res://sounds/god_is_here.mp3")
@onready var timer_label = $TimerLabel  # Assuming a Label node to show the timer

func disable_movement_inputs():
	# Remove the input bindings for movement actions
	InputMap.erase_action("move_forward")
	InputMap.erase_action("move_back")
	InputMap.erase_action("move_left")
	InputMap.erase_action("move_right")
	
	print("Movement keys disabled")

var timer_started = false
var countdown_time = 45.0  # Starting countdown from 45 seconds
var sound_player: AudioStreamPlayer  # Audio stream player for "God is Coming"

func is_spawnable_altar():
	return true
	
func play_ambient_sound(sound_file: AudioStream) -> AudioStreamPlayer:
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	sound_player.stream = sound_file
	sound_player.volume_db = 10
	sound_player.bus = "Ambient"  # Ensure 'Ambient' bus exists in Audio settings
	sound_player.play()
	return sound_player
	
func toggle_walls():
	$Wall1.disabled = !$Wall1.disabled
	$Wall2.disabled = !$Wall2.disabled
	$Wall3.disabled = !$Wall3.disabled
	$Wall4.disabled = !$Wall4.disabled
	$Wall5.disabled = !$Wall5.disabled
	$Wall6.disabled = !$Wall6.disabled
	
func toggle_pillars():
	$RigidBody3D/Pillar1.disabled = true
	$RigidBody3D/Pillar2.disabled = true
	$RigidBody3D/Pillar3.disabled = true
	$RigidBody3D/Pillar4.disabled = true
	$RigidBody3D/Pillar5.disabled = true
	$RigidBody3D/Pillar6.disabled = true
	$MiddleRune.disabled = true

func disable_raycast_for_pillars():
	$RigidBody3D.add_to_group("altar_hitbox")
	
func _ready():
	toggle_walls()
	disable_raycast_for_pillars()

func spawn_boss(player: CharacterBody3D):
	# Play "God is Coming" sound
	toggle_walls()
	timer_started = true
	var coming_player = play_ambient_sound(god_is_coming)

	# Start countdown
	start_countdown()

	# Wait for 45 seconds while the timer updates
	await get_tree().create_timer(45.0).timeout
	$TimerLabel.text = "GOD IS HERE"
	
	# After countdown finishes, play "God is Here" and spawn the boss
	disable_movement_inputs()
	toggle_walls()
	play_ambient_sound(god_is_here)
	spawn_boss_instance(player)

func start_countdown():
	set_process(true)  # Start processing to update the timer

func _process(delta):
	if timer_started and countdown_time > 0:
		countdown_time -= delta
		update_timer_label()
	else:
		set_process(false)  # Stop updating the timer once it reaches 0

func update_timer_label():
	var minutes = int(countdown_time) / 60
	var seconds = int(countdown_time) % 60
	var milliseconds = int((countdown_time - int(countdown_time)) * 1000)
	timer_label.text = "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

func spawn_boss_instance(player: CharacterBody3D):
	# Instance the boss scene
	print("spawning boss")
	var boss_instance = boss_scene.instantiate()
	
	toggle_pillars()
	
	# Calculate spawn position 10 meters behind the player
	var backward_direction = player.global_transform.basis.z.normalized()
	var spawn_offset = backward_direction * 9
	boss_instance.global_transform.origin = player.global_transform.origin + spawn_offset
	
	# Set the boss's yaw to face the player by using the player's rotation
	boss_instance.rotation.y = player.rotation.y + PI
	
	print("Spawned boss at: ", boss_instance.global_transform.origin)
	
	# Add the boss instance to the scene tree
	get_parent().get_parent().add_child(boss_instance)
