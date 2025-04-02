extends CharacterBody3D

var speed = 10.0  # Boss speed

@onready var sound = preload("res://sounds/screech.mp3")
@onready var small_collission = $SmallCollission
@onready var big_collission = $BigCollission
@onready var flat_collission = $FlatCollission

var sound_played = false

func _ready():
	var shape = $CollisionShape3D
	# Set collision layer to a dedicated layer (e.g., layer 3)
	collision_layer = 1 << 2  # 1 << 2 corresponds to layer 3 (bitmask 4)
	
	# Disable all collision responses (mask 0)
	collision_mask = 0


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

var target_position: Vector3
var moving = false

func move_towards_player(player_position: Vector3):
	# Store the target position once
	target_position = player_position
	moving = true  # Start movement

	# Play sound & swap to small collision if needed
	if !sound_played:
		play_ambient_sound(sound, 50.0)
		sound_played = true
		big_collission.disabled = true
		flat_collission.disabled = true
		small_collission.disabled = false

func _physics_process(delta):
	if moving:
		var direction = (target_position - global_transform.origin).normalized()
		velocity = direction * speed
		move_and_slide()

		# Stop moving when close enough
		if global_transform.origin.distance_to(target_position) < 0.1:
			moving = false
			velocity = Vector3.ZERO
			await get_tree().create_timer(3.0).timeout
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().change_scene_to_file("res://scenes/end.tscn")
