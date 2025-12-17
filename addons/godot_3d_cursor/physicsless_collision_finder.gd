class_name PhysicslessCollisionFinder
## This class provides the methods to find collisions on a mesh basis.
##
## This finder is used when [member Plugin3DCursor.raycast_mode] is set to
## [member Plugin3DCursor.RaycastMode.PHYSICSLESS].


## This method determines the candidates detected by the mesh-based raycast.
## The detection is intentionally coarse and does not return an exact hit position.
## Instead, it returns an [code]Array[Node][/code] containing every [Node] with a [Mesh]
## that was hit by the ray.
func _get_candidates(from: Vector3, to: Vector3, editor_camera: Camera3D) -> Array[Node]:
	# Get the World3D from the camera
	var world: World3D = editor_camera.get_world_3d()
	# When the world is null we can't perform the raycast so we return early
	if world == null:
		return []

	# We take the scenario
	var scenario: RID = world.scenario

	# The raycast returns a list of IDs for every Node with a mesh that was hit by the ray
	var ids: PackedInt64Array = RenderingServer.instances_cull_ray(from, to, scenario)
	# We create an empty array that will hold the nodes associated to the ids we got before
	var hits: Array[Node] = []

	# Iterate over all IDs, get the associated objects and cast them to Node before appending them
	# to the hits-Array
	for id in ids:
		var obj: Object = instance_from_id(id)
		if obj is Node:
			hits.append(obj)

	# Return the list filled with Nodes that were hit by the ray
	return hits



## This method attempts to convert a [Mesh] into a [TriangleMesh], returning [code]null[/code]
## if the conversion fails.
func _get_triangle_mesh(mesh: Mesh) -> TriangleMesh:
	# When the mesh is null we return null
	if mesh == null:
		return null

	# If there are no faces in the mesh we return null as well
	var faces: PackedVector3Array = mesh.get_faces()
	if faces.is_empty():
		return null

	# We create a new empty TriangleMesh
	var tri: TriangleMesh = TriangleMesh.new()
	# We try to create the TriangleMesh from the faces and return null if we fail
	if not tri.create_from_faces(faces):
		return null

	# Return the new TriangleMesh constructed from a normal Mesh
	return tri


## This method computes the exact hit point on the mesh in global space.
## It does so by converting the [Mesh] of the [param mesh_instance] into a [TriangleMesh],
## transforming the ray into local space, and using the dedicated intersection method
## [member TriangleMesh.intersect_segment].
##
## The method returns a [Dictionary] containing the following string keys:[br][br]
## - [code]"position"[/code],[br][br]
## - [code]"normal"[/code],[br][br]
## - [code]"node"[/code] (a reference to the mesh [MeshInstance3D]),[br][br]
func _hit_mesh_segment(mesh_instance: MeshInstance3D, from: Vector3, to: Vector3) -> Dictionary:
	# Get the mesh from the MeshInstance3D
	var mesh: Mesh = mesh_instance.mesh
	# Convert the mesh to a TriangleMesh
	var tri: TriangleMesh = _get_triangle_mesh(mesh)
	# Make sure the mesh was converted successfully
	if tri == null:
		return {}

	# Transform Ray/Segment in Local Space
	var inv: Transform3D = mesh_instance.global_transform.affine_inverse()
	var local_from: Vector3 = inv * from
	var local_to: Vector3 = inv * to

	# Get the exact hit point on the mesh
	var hit: Dictionary = tri.intersect_segment(local_from, local_to)
	# If the hit is empty it means there is no hit. Shouldn't happen though
	if hit.is_empty():
		return {}

	# Hit back to World/Global space
	hit["position"] = mesh_instance.global_transform * hit.position
	hit["normal"] = (mesh_instance.global_transform.basis * hit.normal).normalized()
	hit["node"] = mesh_instance
	return hit


## This method locates the root [CSGShape3D] required to build a mesh.
func _find_csg_root(shape: CSGShape3D) -> CSGShape3D:
	# This is the current shape we are looking at
	var current: Node = shape
	# We search as long for a higher CSGShape3D until current is null
	while current != null:
		# If the current shape is not a CSGShape3D we get its parent and go to the next iteration
		# of the loop
		if not current is CSGShape3D:
			current = current.get_parent()
			continue

		# When we found another CSGShape3D we cast it as one and save it
		var csg: CSGShape3D = current as CSGShape3D
		# If the shape is the root we return it
		if csg.is_root_shape():
			return csg

		# If the shape was not the root we get its parent, save it in current
		# and go to the next iteration of the loop
		current = current.get_parent()

	# If no root CSGShape3D was found, we return null
	return null


## This method works similarly to [member PhysicslessCollisionFinder._hit_mesh_segment].
## First, it bakes an [ArrayMesh] from the [param csg_root] and converts it into a
## [TriangleMesh], which is then used to compute the exact hit point in local space
## using [member TriangleMesh.intersect_segment].[br][br]
##
## The method returns a [Dictionary] containing the following string keys:[br][br]
## - [code]"position"[/code],[br][br]
## - [code]"normal"[/code],[br][br]
## - [code]"csg_root"[/code] (a reference to the root [CSGShape3D]),[br][br]
## - [code]"csg_shape"[/code] (the [CSGShape3D] instance the method was invoked with)
func _hit_csg_segment(csg_any: CSGShape3D, from: Vector3, to: Vector3) -> Dictionary:
	# The root of CSGShape3D of the csg_any
	var csg_root: CSGShape3D = _find_csg_root(csg_any)
	# If there is no root we return an empty hit-Dictionary
	if csg_root == null:
		return {}

	# We bake an ArrayMesh out of the csg_root
	var baked: ArrayMesh = csg_root.bake_static_mesh()
	# If the bake didn't work out or we have zero faces we try again after the next process frame
	if baked == null or baked.get_surface_count() == 0:
		await csg_root.get_tree().process_frame
		baked = csg_root.bake_static_mesh()

	# If the baking still did not succeed we return an empty hit-Dictionary
	if baked == null or baked.get_surface_count() == 0:
		return {}

	# If the build succeeded we extract the faces
	var faces: PackedVector3Array = baked.get_faces()
	# If the faces are empty we return. This shouldn't happen at this point though
	if faces.is_empty():
		return {}

	# We create a TriangleMesh and build it from the faces we extracted.
	# If this does not work we return an empty hit-Dictionary
	var tri: TriangleMesh = TriangleMesh.new()
	if not tri.create_from_faces(faces):
		return {}

	# Transform Ray/Segment in Local Space
	var inv: Transform3D = csg_root.global_transform.affine_inverse()
	var local_from: Vector3 = inv * from
	var local_to: Vector3 = inv * to

	# We get the hit position from the TriangleMesh
	var hit: Dictionary = tri.intersect_segment(local_from, local_to)
	# If there is no hit we return an empty hit
	if hit.is_empty():
		return {}

	# Hit back to World/Global space
	hit["position"] = csg_root.global_transform * hit["position"]
	hit["normal"] = (csg_root.global_transform.basis * hit["normal"]).normalized

	hit["csg_root"] = csg_root
	hit["csg_shape"] = csg_any

	return hit


## This method computes the closest collision by processing all hits on
## [MeshInstance3D] and [CSGShape3D] instances.
func get_closest_collision(from: Vector3, to: Vector3, editor_camera: Camera3D) -> Dictionary:
	# First we calculate all candidates and store them
	var candidates: Array[Node] = _get_candidates(from, to, editor_camera)

	# This dictionary will hold the best/closest hit encountered so far
	var best_hit: Dictionary = {}
	# This float will hold the best/closest/shortest distance encountered so far; Initially INF
	var best_dist: float = INF
	# We iterate over all candidates
	for candidate in candidates:
		# We create temporary hit-Dictionary that we will compare to our best_hit later
		var hit: Dictionary
		# When the candidate is a MeshInstance3D we use a dedicated method
		if candidate is MeshInstance3D:
			hit = _hit_mesh_segment(candidate, from, to)
		# If the candidate is a CSGShape3D we use another method
		elif candidate is CSGShape3D:
			hit = await _hit_csg_segment(candidate, from, to)

		# If the Terrain3D plugin is installed we check our hit againt the Terrain-Checker as well
		if ClassDB.class_exists("Terrain3D"):
			hit = Terrain3DExtension.get_closest_hit_point(
				candidate.get_tree().get_nodes_in_group("Terrain3D"),
				from, to
			)

		# When the current hit is empty we go to the next iteration of the loop
		if hit.is_empty():
			continue

		# We calculate the distance from 'from' to the hit's position and store it
		var distance: float = from.distance_to(hit["position"])
		# When the distance is shorter than the best_dist we store it in best_dist as well
		# as the current hit in best_hit
		if distance < best_dist:
			best_dist = distance
			best_hit = hit

	# After iterating over all candidates we return the best hit
	return best_hit
