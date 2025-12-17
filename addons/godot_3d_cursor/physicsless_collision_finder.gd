class_name PhysicslessCollisionFinder

var _tri_cache: Dictionary[Mesh, TriangleMesh] = {}

func _get_candidates(from: Vector3, to: Vector3, editor_camera: Camera3D) -> Array[Node]:
	var world: World3D = editor_camera.get_world_3d()
	if world == null:
		return []

	var scenario: RID = world.scenario

	var ids: PackedInt64Array = RenderingServer.instances_cull_ray(from, to, scenario)
	var hits: Array[Node] = []

	for id in ids:
		var obj: Object = instance_from_id(id)
		if obj is Node:
			hits.append(obj)

	return hits


func _get_triangle_mesh(mesh: Mesh) -> TriangleMesh:
	if mesh == null:
		return null

	if _tri_cache.has(mesh):
		return _tri_cache[mesh]

	var faces: PackedVector3Array = mesh.get_faces()
	if faces.is_empty():
		return null

	var tri: TriangleMesh = TriangleMesh.new()
	if not tri.create_from_faces(faces):
		return null

	_tri_cache[mesh] = tri
	return tri


func _hit_mesh_segment(mesh_instance: MeshInstance3D, from: Vector3, to: Vector3) -> Dictionary:
	var mesh: Mesh = mesh_instance.mesh
	var tri: TriangleMesh = _get_triangle_mesh(mesh)
	if tri == null:
		return {}

	# Ray/Segment in Local Space
	var inv: Transform3D = mesh_instance.global_transform.affine_inverse()
	var local_from: Vector3 = inv * from
	var local_to: Vector3 = inv * to

	var hit: Dictionary = tri.intersect_segment(local_from, local_to)
	if hit.is_empty():
		return {}

	# Hit back to world space
	hit["position"] = mesh_instance.global_transform * hit.position
	hit["normal"] = (mesh_instance.global_transform.basis * hit.normal).normalized()
	hit["node"] = mesh_instance
	return hit


func _find_csg_root(shape: CSGShape3D) -> CSGShape3D:
	var current: Node = shape
	while current != null:
		if not current is CSGShape3D:
			current = current.get_parent()
			continue

		var csg: CSGShape3D = current as CSGShape3D
		if csg.is_root_shape():
			return csg
		current = current.get_parent()
	return null


func _hit_csg_segment(csg_any: CSGShape3D, from: Vector3, to: Vector3) -> Dictionary:
	var csg_root: CSGShape3D = _find_csg_root(csg_any)
	if csg_root == null:
		return {}

	var baked: ArrayMesh = csg_root.bake_static_mesh()
	if baked == null or baked.get_surface_count() == 0:
		await csg_root.get_tree().process_frame
		baked = csg_root.bake_static_mesh()

	if baked == null or baked.get_surface_count() == 0:
		return {}

	var faces: PackedVector3Array = baked.get_faces()
	if faces.is_empty():
		return {}

	var tri: TriangleMesh = TriangleMesh.new()
	if not tri.create_from_faces(faces):
		return {}

	var inv: Transform3D = csg_root.global_transform.affine_inverse()
	var local_from: Vector3 = inv * from
	var local_to: Vector3 = inv * to

	var hit: Dictionary = tri.intersect_segment(local_from, local_to)
	if hit.is_empty():
		return {}

	hit["position"] = csg_root.global_transform * hit["position"]
	hit["normal"] = (csg_root.global_transform.basis * hit["normal"]).normalized

	hit["csg_root"] = csg_root
	hit["csg_shape"] = csg_any

	return hit


func get_closest_collision(from: Vector3, to: Vector3, editor_camera: Camera3D) -> Dictionary:
	var candidates: Array[Node] = _get_candidates(from, to, editor_camera)

	var best_hit: Dictionary = {}
	var best_dist: float = INF
	for candidate in candidates:
		var hit: Dictionary
		if candidate is MeshInstance3D:
			hit = _hit_mesh_segment(candidate, from, to)
		elif candidate is CSGShape3D:
			hit = await _hit_csg_segment(candidate, from, to)
		if ClassDB.class_exists("Terrain3D"):
			hit = Terrain3DExtension.get_closest_hit_point(
				candidate.get_tree().get_nodes_in_group("Terrain3D"),
				from, to
			)
		if hit.is_empty():
			continue
		var distance: float = from.distance_to(hit["position"])
		if distance < best_dist:
			best_dist = distance
			best_hit = hit
	return best_hit
