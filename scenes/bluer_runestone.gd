extends CharacterBody3D

@export var runestone_type = "colossal"  # "magma", "blue", or "bluer"

func get_runestone_type() -> String:
	return runestone_type

func collect_runestone(player):
	# Call the player's method to update inventory/HUD
	if player.has_method("collect_runestone"):
		player.collect_runestone(runestone_type)
	# Optionally, play a sound or animation here
	queue_free()  # Remove the runestone from the scene
