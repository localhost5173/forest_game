extends Node3D
class_name Chunk

const WATER_LEVEL = -6.0

var mesh_instance: MeshInstance3D
var noise: FastNoiseLite
var x: float
var z: float
var chunk_size: float
var should_remove: bool = true
@onready var tree_scene = preload("res://scenes/tree.tscn")
@onready var altar = preload("res://scenes/altar.tscn")
@onready var magma_runestone = preload("res://scenes/magma_runestone.tscn")
@onready var bluer_runestone = preload("res://scenes/blue_runestone.tscn")
@onready var blue_runestone = preload("res://scenes/bluer_runestone.tscn")

func _init(p_noise: FastNoiseLite, p_x: float, p_z: float, p_chunk_size: float):
	noise = p_noise
	x = p_x
	z = p_z
	chunk_size = p_chunk_size
	should_remove = true

func _ready():
	generate_chunk()
	should_remove = false

func generate_chunk():
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = int(chunk_size * 0.5)
	plane_mesh.subdivide_width = int(chunk_size * 0.5)
	plane_mesh.material = preload("res://grass.material")
	
	var surface_tool := SurfaceTool.new()
	var data_tool := MeshDataTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var array_plane := surface_tool.commit()
	
	var error := data_tool.create_from_surface(array_plane, 0)
	if error != OK:
		print("Error creating surface: ", error)
		return
	
	for i in range(data_tool.get_vertex_count()):
		var vertex = data_tool.get_vertex(i)
		# Adjust height based on noise
		vertex.y = noise.get_noise_3d(vertex.x + x, vertex.y, vertex.z + z) * 33
		data_tool.set_vertex(i, vertex)
	
	# Clear existing surfaces
	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)
	
	# Commit modified vertices
	data_tool.commit_to_surface(array_plane)
	
	# Regenerate mesh with normals
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_plane, 0)
	surface_tool.generate_normals()
	
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.create_trimesh_collision()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	
	# Generate water first so that WATER_LEVEL is defined for runestone placement
	generate_water()
	
	# Spawn objects: altars, trees, then runestones
	var altar_positions = spawn_altars()
	var tree_positions = spawn_trees(altar_positions)
	spawn_runestones(altar_positions, tree_positions)

func generate_water():
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.material = preload("res://water.material")
	
	var water_instance = MeshInstance3D.new()
	water_instance.mesh = plane_mesh
	# Position the water plane at WATER_LEVEL
	water_instance.position.y = WATER_LEVEL
	add_child(water_instance)

func spawn_altars():
	var density = 0.0007  # Rare altars
	var step = 4.0
	var altar_positions = []
	
	for i in range(0, int(chunk_size), int(step)):
		for j in range(0, int(chunk_size), int(step)):
			var world_x = x - chunk_size / 2 + i
			var world_z = z - chunk_size / 2 + j
			var world_y = noise.get_noise_3d(world_x, 0, world_z) * 33
			if randf() < density and world_y > -5.0:
				var altar_instance = altar.instantiate()
				var local_x = world_x - x
				var local_z = world_z - z
				altar_instance.position = Vector3(local_x, world_y, local_z)
				altar_instance.rotation.y = randf() * TAU
				add_child(altar_instance)
				altar_positions.append(Vector2(local_x, local_z))
	return altar_positions

func spawn_trees(altar_positions):
	var tree_count = 0
	var density = 0.15
	var step = 2.0
	var tree_positions = []
	
	for i in range(0, int(chunk_size), int(step)):
		for j in range(0, int(chunk_size), int(step)):
			var world_x = x - chunk_size / 2 + i
			var world_z = z - chunk_size / 2 + j
			var world_y = noise.get_noise_3d(world_x, 0, world_z) * 33
			
			# Skip if too close to any altar (within 2m)
			var too_close = false
			for altar_pos in altar_positions:
				if Vector2(world_x - x, world_z - z).distance_to(altar_pos) < 10.0:
					too_close = true
					break
			if too_close:
				continue

			if randf() < density and world_y > -5.0:
				var tree_instance = tree_scene.instantiate()
				var local_x = world_x - x
				var local_z = world_z - z
				tree_instance.position = Vector3(local_x, world_y - 1, local_z)
				tree_instance.rotation.y = randf() * TAU
				add_child(tree_instance)
				tree_positions.append(Vector2(local_x, local_z))
				tree_count += 1
	print("Spawned ", tree_count, " trees.")
	return tree_positions

func spawn_runestones(altar_positions, tree_positions):
	var density = 0.0045
	var step = 2.0
	var runestone_positions = []
	var runestone_count = 0
	
	for i in range(0, int(chunk_size), int(step)):
		for j in range(0, int(chunk_size), int(step)):
			var world_x = x - chunk_size / 2 + i
			var world_z = z - chunk_size / 2 + j
			var world_y = noise.get_noise_3d(world_x, 0, world_z) * 33
			var local_pos = Vector2(world_x - x, world_z - z)
			
			# Check if too close to trees, altars, or other runestones (using a 2m radius)
			var too_close = false
			for pos in tree_positions:
				if local_pos.distance_to(pos) < 2.0:
					too_close = true
					break
			if too_close:
				continue
			for pos in altar_positions:
				if local_pos.distance_to(pos) < 2.0:
					too_close = true
					break
			if too_close:
				continue
			for pos in runestone_positions:
				if local_pos.distance_to(pos) < 2.0:
					too_close = true
					break
			if too_close:
				continue
			
			if randf() < density:
				# Randomly select a runestone type: 0 = magma, 1 = blue, 2 = bluer
				var runestone_type = randi() % 3
				var instance = null
				if runestone_type == 0:
					instance = magma_runestone.instantiate()
				elif runestone_type == 1:
					instance = blue_runestone.instantiate()
				elif runestone_type == 2:
					# Bluer runestones only spawn underwater
					if world_y > WATER_LEVEL:
						continue
					instance = bluer_runestone.instantiate()
				if instance:
					instance.position = Vector3(local_pos.x, world_y, local_pos.y)
					instance.rotation.y = randf() * TAU
					add_child(instance)
					runestone_positions.append(local_pos)
					runestone_count += 1
	print("Spawned ", runestone_count, " runestones.")
