@tool
extends MeshInstance3D
class_name MaskedPlanet

var nav_astar: AStar3D


@export var settings: PlanetSettings:
	set(v):
		settings = v
		# Listen for any changes inside the resource to rebuild the mesh
		if settings and not settings.changed.is_connected(generate):
			settings.changed.connect(generate)
		generate()

func _ready() -> void:
	
	generate()
	


func generate() -> void:
	# Don't generate if we are missing the resource or its noises
	if not is_inside_tree() or not settings:
		return
	if not settings.terrain_noise or not settings.continent_mask:
		return

	var base_sphere := SphereMesh.new()
	base_sphere.radius = settings.radius
	base_sphere.height = settings.radius * 2.0
	base_sphere.radial_segments = settings.resolution * 2
	base_sphere.rings = settings.resolution
	
	var arrays: Array = base_sphere.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	colors.resize(verts.size())
	
	for i in verts.size():
		var dir: Vector3 = verts[i].normalized()
		
		var surface_point = get_surface_point(dir)
		
		verts[i] = surface_point[0]
		colors[i] = Color(surface_point[1], surface_point[1], surface_point[1], 1.0)

	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	st.generate_normals()
	
	mesh = st.commit()
	nav_astar = build_nav_graph(settings.nav_subdiv)



func get_surface_point(dir:Vector3):
			
		var raw_mask: float = settings.continent_mask.get_noise_3dv(dir * 100.0)
		var mask_level: float = clamp((raw_mask + 1.0) * 0.5, 0.0, 1.0)
		mask_level = pow(mask_level, settings.mask_sharpness)
		
		
		var raw_noise: float = settings.terrain_noise.get_noise_3dv(dir * 100.0)
		var height_level: float = 1.0 - abs(raw_noise)
		height_level = pow(height_level, 3.0)
		
		
		# Raising the height to a power curves the data. 
		# Low/mid values get squashed, high values stay high.
		height_level = pow(height_level, settings.mountain_exponent) 
		
	
		var final_height_level: float = height_level * mask_level
		var offset: float = final_height_level * settings.mountain_height
		return [dir * (settings.radius + offset), final_height_level]

func generate_icosphere_directions(subdivisions: int) -> Dictionary:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	for i in verts.size():
		verts[i] = verts[i].normalized()

	var faces: Array = [
		[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
		[1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
		[3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
		[4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1],
	]

	for s in subdivisions:
		var new_faces := []
		var cache := {}
		for f in faces:
			var a = _get_or_add_midpoint(verts, cache, f[0], f[1])
			var b = _get_or_add_midpoint(verts, cache, f[1], f[2])
			var c = _get_or_add_midpoint(verts, cache, f[2], f[0])
			new_faces.append([f[0], a, c])
			new_faces.append([f[1], b, a])
			new_faces.append([f[2], c, b])
			new_faces.append([a, b, c])
		faces = new_faces

	return {"verts": verts, "faces": faces}

func _get_or_add_midpoint(verts: Array, cache: Dictionary, a: int, b: int) -> int:
	var key = str(min(a, b)) + "_" + str(max(a, b))
	if cache.has(key):
		return cache[key]
	var mid: Vector3 = ((verts[a] + verts[b]) * 0.5).normalized()
	verts.append(mid)
	cache[key] = verts.size() - 1
	return cache[key]

func build_nav_graph(subdivisions: int = 4) -> AStar3D:
	var astar := AStar3D.new()
	var ico = generate_icosphere_directions(subdivisions)
	var verts: Array = ico["verts"]
	var faces: Array = ico["faces"]

	var heights := []
	for i in verts.size():
		var sp = get_surface_point(verts[i])   # reuse your real terrain function
		astar.add_point(i, sp[0])
		heights.append(sp[1])                  # final_height_level, 0..1

	var edges := {}
	for f in faces:
		for e in [[0,1],[1,2],[2,0]]:
			var a = f[e[0]]
			var b = f[e[1]]
			var key = str(min(a,b)) + "_" + str(max(a,b))
			if edges.has(key):
				continue
			edges[key] = true
			if heights[a] <= 0.01 or heights[b] <= 0.01:
				continue  # matches your spawn_objects underwater/lowland skip
			astar.connect_points(a, b)
	return astar

func GetPath(from_pos: Vector3, to_pos: Vector3) -> PackedVector3Array:
	if not nav_astar:
		return PackedVector3Array()
	var from_id := nav_astar.get_closest_point(from_pos)
	var to_id := nav_astar.get_closest_point(to_pos)
	return nav_astar.get_point_path(from_id, to_id)


func debug_draw_path(path: PackedVector3Array) -> void:
	for p in path:
		var marker := CSGSphere3D.new()
		marker.radius = 0.1
		marker.position = p
		add_child(marker)
#func spawn_objects(spawn_dict:Dictionary[PackedScene,int]):
	#if spawn_dict.is_empty():
		#return
		#
	## Outer loop: 'prefab' is the key (the PackedScene)
	#for prefab in spawn_dict:
		## The value tied to that key is our count (the integer)
		#var count: int = spawn_dict[prefab]
		#
		## Inner loop: spawns this specific prefab 'count' times
		#for i in count:
			#var random_dir := Vector3(
				#randfn(0.0, 1.0), 
				#randfn(0.0, 1.0), 
				#randfn(0.0, 1.0)
			#).normalized()
			#
			#var surface_point: Vector3 = get_surface_point(random_dir)
			#
			## Skip underwater/lowland spawns
			#if surface_point.length() <= settings.radius + 0.1:
				#continue 
				#
			## Instantiate using the key
			#var obj := prefab.instantiate() as Node3D
			#add_child(obj)
			#
			#obj.position = surface_point
			#obj.quaternion = Quaternion(Vector3.UP, random_dir)
			#obj.rotate_object_local(Vector3.UP, randf_range(0.0, TAU))
	#
