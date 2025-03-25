extends Node3D

@onready var player_scene = preload("res://scenes/player.tscn")
@onready var tree_scene = preload("res://scenes/tree.tscn")
@onready var world_env = $WorldEnvironment

var fullbright_enabled := false
var noise: FastNoiseLite
const CHUNK_SIZE = 64
const CHUNK_AMOUNT = 16
var chunks: Dictionary = {}
var unready_chunks: Dictionary = {}
var player: Node3D

func _ready():
	# In Godot 4, randomize() is replaced by setting a random seed
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 1.0 / 80.0
	noise.fractal_octaves = 6
	
	spawn_player()
	spawn_trees(5)

func add_chunk(x: int, z: int) -> void:
	var key: String = str(x) + "," + str(z)
	if chunks.has(key) or unready_chunks.has(key):
		return
		
	var new_thread := Thread.new()
	new_thread.start(func(): return load_chunk(new_thread, x, z))
	unready_chunks[key] = new_thread

func load_chunk(thread: Thread, x: int, z: int) -> Chunk:
	var chunk := Chunk.new(noise, x * CHUNK_SIZE, z * CHUNK_SIZE, CHUNK_SIZE)
	chunk.position = Vector3(x * CHUNK_SIZE, 0, z * CHUNK_SIZE)
	call_deferred("load_done", chunk, thread)
	return chunk

func load_done(chunk: Chunk, thread: Thread) -> void:
	add_child(chunk)
	var key: String = str(chunk.x / CHUNK_SIZE) + "," + str(chunk.z / CHUNK_SIZE)
	chunks[key] = chunk
	unready_chunks.erase(key)
	thread.wait_to_finish()

func get_chunk(x: int, z: int) -> Chunk:
	var key: String = str(x) + "," + str(z)
	return chunks.get(key)

func _process(delta: float) -> void:
	update_chunks()
	clean_up_chunks()
	reset_chunks()

func update_chunks() -> void:
	print("Updating chunks")
	if player == null:
		return
	
	var player_position: Vector3 = player.global_position
	var p_x: int = int(player_position.x) / CHUNK_SIZE
	var p_z: int = int(player_position.z) / CHUNK_SIZE
	
	for x in range(p_x - int(CHUNK_AMOUNT * 0.5), p_x + int(CHUNK_AMOUNT * 0.5)):
		for z in range(p_z - int(CHUNK_AMOUNT * 0.5), p_z + int(CHUNK_AMOUNT * 0.5)):
			add_chunk(x, z)

func clean_up_chunks() -> void:
	pass

func reset_chunks() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullbright"):
		fullbright_enabled = !fullbright_enabled
		update_fullbright()

func update_fullbright() -> void:
	if world_env and world_env.environment:
		if fullbright_enabled:
			world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			world_env.environment.ambient_light_energy = 2.0
			world_env.environment.ambient_light_color = Color.WHITE
		else:
			world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_BG
			world_env.environment.ambient_light_energy = 1.0
			world_env.environment.ambient_light_color = Color.BLACK

func spawn_player() -> void:
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector3(0, 1, 0)

func spawn_trees(count: int) -> void:
	for i in range(count):
		var tree := tree_scene.instantiate()
		add_child(tree)
		tree.global_position = Vector3(
			randf_range(-10, 10), 
			0, 
			randf_range(-10, 10)
		)
