extends Node3D  # Ensure it's Node3D to support 3D transforms

@onready var player_scene = preload("res://scenes/player.tscn")
@onready var tree_scene = preload("res://scenes/tree.tscn")  # Load tree scene

func _ready():
	spawn_player()
	spawn_trees(5)  # Spawn 5 trees

func spawn_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.global_transform.origin = Vector3(0, 1, 0)  # Set initial position

func spawn_trees(count: int):
	for i in range(count):
		var tree = tree_scene.instantiate()
		add_child(tree)
		tree.global_transform.origin = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))  # Random positions
