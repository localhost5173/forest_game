extends Node3D

@onready var player_scene = preload("res://scenes/player.tscn")
@onready var world_env = $WorldEnvironment

var fullbright_enabled := false
var noise: FastNoiseLite
const CHUNK_SIZE = 64
const CHUNK_AMOUNT = 4
var chunks: Dictionary = {}
var unready_chunks: Dictionary = {}
var player: Node3D

func _ready():
	# In Godot 4, randomize() is replaced by setting a random seed
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 1.0 / 80.0
	noise.fractal_octaves = 6
	
	spawn_player()

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
	call_deferred("load_done", chunk, thread, x, z)
	return chunk

func load_done(chunk: Chunk, thread: Thread, x: int, z: int) -> void:
	add_child(chunk)
	var key: String = str(x) + "," + str(z)
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
	if player == null:
		return
	
	var player_position: Vector3 = player.global_position
	var p_x: int = int(player_position.x) / CHUNK_SIZE
	var p_z: int = int(player_position.z) / CHUNK_SIZE
	
	var active_chunks: Dictionary = {}
	
	for x in range(p_x - int(CHUNK_AMOUNT * 0.5), p_x + int(CHUNK_AMOUNT * 0.5)):
		for z in range(p_z - int(CHUNK_AMOUNT * 0.5), p_z + int(CHUNK_AMOUNT * 0.5)):
			add_chunk(x, z)
			var chunk = get_chunk(x, z)
			if chunk != null:
				var chunk_key: String = str(x) + "," + str(z)
				active_chunks[chunk_key] = chunk

	# Mark chunks outside active area for removal
	for key in chunks:
		if not active_chunks.has(key):
			chunks[key].should_remove = true
		else:
			chunks[key].should_remove = false

func clean_up_chunks() -> void:
	var chunks_to_remove: Array = []
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			chunk.queue_free()
			chunks_to_remove.append(key)
	
	for key in chunks_to_remove:
		chunks.erase(key)

func reset_chunks() -> void:
	pass  # Removed this as it was causing unnecessary chunk removal

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
	player.global_position = Vector3(0, 10, 0)
