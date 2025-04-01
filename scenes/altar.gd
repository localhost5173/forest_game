extends CharacterBody3D

@onready var boss_scene = preload("res://scenes/boss.tscn")

func is_spawnable_altar():
	return true

func spawn_boss(player_pos: Vector3):
	# Instance the boss scene
	print("spawning boss")
	var boss_instance = boss_scene.instantiate()
	
	# Set the boss's position 10 meters above the altar
	boss_instance.global_transform.origin = player_pos + Vector3(0, 0, 7)
	print("Spawned boss at: ", player_pos + Vector3(0, 10, 0))
	
	# Add the boss instance to the scene tree
	get_parent().get_parent().add_child(boss_instance)
