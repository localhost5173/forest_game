extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.1

@onready var camera = $Camera3D
@onready var flashlight = $Camera3D/SpotLight3D

var velocity_dir := Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Lock mouse

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
		camera.rotate_x(-event.relative.y * mouse_sensitivity * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	if event.is_action_pressed("toggle_flashlight"):
		flashlight.visible = !flashlight.visible  # Toggle flashlight

func _physics_process(_delta):
	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	
	input_dir = input_dir.rotated(Vector3.UP, rotation.y).normalized()
	velocity_dir = input_dir * speed
	velocity = velocity_dir
	move_and_slide()
