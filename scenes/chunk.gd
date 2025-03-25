extends Node3D
class_name Chunk

var mesh_instance: MeshInstance3D
var noise: FastNoiseLite
var x: float
var z: float
var chunk_size: float

func _init(p_noise: FastNoiseLite, p_x: float, p_z: float, p_chunk_size: float):
	noise = p_noise
	x = p_x
	z = p_z
	chunk_size = p_chunk_size

func _ready():
	generate_chunk()

func generate_chunk():
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = int(chunk_size * 0.5)
	plane_mesh.subdivide_width = int(chunk_size * 0.5)
	
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
		vertex.y = noise.get_noise_3d(vertex.x + x, vertex.y, vertex.z + z) * 80
		
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
