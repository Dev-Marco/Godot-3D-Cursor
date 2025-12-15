class_name PhysicsCollisionFinder

func get_closest_collision(from: Vector3, to: Vector3, world_3d: World3D) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	var hit: Dictionary = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	return hit
