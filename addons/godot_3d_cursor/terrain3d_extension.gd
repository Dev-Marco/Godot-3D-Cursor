## This class implements a Terrain3D-specific extension for the 3D Cursor plugin.
## It is used internally to provide Terrain3D compatibility and is not part of the public API.
class_name Terrain3DExtension

## This method relies on an exposed [Terrain3D] method ([method Terrain3D.get_intersection])
## to compute the closest hit point along a ray cast from the mouse position.
## The ray is cast from [param from] to [code](to - from).normalized()[/code], and each [Terrain3D]
## instance is queried to determine the closest intersection.
static func get_closest_hit_point(terrains: Array[Node], from: Vector3, to: Vector3) -> Dictionary:
	# This dictionary is returned on a successful intersection and contains positional data,
	# the surface normal, and the associated node.
	var best_hit: Dictionary = {}
	# This float stores the shortest distance to the closest intersection found so far.
	var best_dist: float = INF
	# This Vector3 represents the direction used for intersection calculations.
	var direction: Vector3 = (to - from).normalized()

	# We iterate over the provided Terrain3D instances.
	for terrain: Node in terrains:
		if not terrain.has_method("get_intersection"):
			continue
		# We calculate the intersection for each Terrain3D instance and store it.
		var hit_point: Vector3 = terrain.get_intersection(from, direction, false)

		# Validate the result and return early with an empty Dictionary if it is invalid.
		if is_nan(hit_point.z) or hit_point.z > 3.4e38:
			return {}

		# Calculate distance to the hit point
		var dist = from.distance_to(hit_point)

		# Store the hit point if it is closer than the best one found so far.
		if dist < best_dist:
			best_dist = dist
			best_hit = {
				"position": hit_point,
				"normal": Vector3.UP,
				"node": terrain
			}

	# Return the best (closest) hit point found.
	return best_hit
