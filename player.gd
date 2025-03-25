extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.1
@export var jump_speed := 5.0
@export var gravity := 9.8
@export var fly_speed := 40

@onready var camera = $Camera3D
@onready var flashlight = $Camera3D/SpotLight3D

var velocity_dir := Vector3.ZERO
var is_flying := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Lock mouse

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
		camera.rotate_x(-event.relative.y * mouse_sensitivity * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	if event.is_action_pressed("toggle_flashlight"):
		flashlight.visible = !flashlight.visible  # Toggle flashlight
	
	# Toggle flying mode when "fly" action is pressed
	if event.is_action_pressed("fly"):
		is_flying = !is_flying
		print("Flying mode toggled: ", is_flying)

func _physics_process(_delta):
	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")

	input_dir = input_dir.rotated(Vector3.UP, rotation.y).normalized()

	if is_flying:
		velocity_dir = input_dir * fly_speed  # Use flying speed
		if Input.is_action_pressed("jump"):
			velocity.y = fly_speed
		elif Input.is_action_pressed("crouch"):
			velocity.y = -fly_speed
		else:
			velocity.y = 0  # No vertical movement if neither pressed
	else:
		velocity_dir = input_dir * speed  # Use walking speed
		if not is_on_floor():
			velocity.y -= gravity * _delta
		else:
			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_speed

	# Apply velocity
	velocity.x = velocity_dir.x
	velocity.z = velocity_dir.z

	move_and_slide()
