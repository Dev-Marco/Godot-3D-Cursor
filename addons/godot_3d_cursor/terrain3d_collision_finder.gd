## This class provides an extension for the 3D-Cursor plugin to achieve compatibility
## with the popular Terrain3D addon.
class_name Terrain3DCollisionFinder


static func get_closest_hit_point(terrains: Array[Node], from: Vector3, to: Vector3) -> Dictionary:
	print_debug("in terrain")
	print_debug(terrains)
	var best_hit: Dictionary = {}
	var best_dist: float = INF
	var direction: Vector3 = (to - from).normalized()

	for terrain: Terrain3D in terrains:
		var point: Vector3 = terrain.get_intersection(from, direction, false)
		if is_nan(point.z) or point.z > 3.4e38:
			return {}

		var dist = from.distance_to(point)
		if dist < best_dist:
			best_dist = dist
			best_hit = {
				"position": point,
				"normal": Vector3.UP,
				"node": terrain
			}
	print_debug(best_hit)
	return best_hit
