extends Node3D
class_name Chunk

var mesh_instance: MeshInstance3D
var noise: FastNoiseLite
var x: float
var z: float
var chunk_size: float
var should_remove: bool = true
@onready var tree_scene = preload("res://scenes/tree.tscn")

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
		var vertex := data_tool.get_vertex(i)
		
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
	
	# Add collision
	mesh_instance.create_trimesh_collision()
	
	# Disable shadow casting
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Add the mesh instance as a child
	add_child(mesh_instance)
	
	# Spawn trees naturally, very nice!
	spawn_trees()
	generate_water()
	
func generate_water():
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.material = preload("res://water.material")
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane_mesh
	
	# Calculate water level - trees spawn when world_y > -5.0, so lowest tree would be at -5.0
	# We want water 1m below that, so -6.0
	var water_level = -6.0
	
	# Position the water plane at this level
	mesh_instance.position.y = water_level
	
	add_child(mesh_instance)

func spawn_trees():
	var tree_count = 0
	var density = 0.15
	var step = 2.0
	for i in range(0, int(chunk_size), int(step)):
		for j in range(0, int(chunk_size), int(step)):
			var world_x = x - chunk_size / 2 + i
			var world_z = z - chunk_size / 2 + j
			var world_y = noise.get_noise_3d(world_x, 0, world_z) * 33
			if randf() < density and world_y > -5.0:
				var tree_instance = tree_scene.instantiate()
				# Calculate local position relative to chunk's origin
				var local_x = world_x - x
				var local_z = world_z - z
				tree_instance.position = Vector3(local_x, world_y - 1, local_z)
				tree_instance.rotation.y = randf() * TAU
				add_child(tree_instance)
				tree_count += 1
	print("Spawned ", tree_count, " trees.")
