extends CharacterBody3D

var speed = 5.0  # Boss speed

# Function to move the boss towards the player
func move_towards_player(player_position: Vector3, delta: float):
	var direction = (player_position - global_transform.origin).normalized()  # Get direction to player
	velocity = direction * speed  # Move boss towards the player
	move_and_slide()  # Apply movementw
