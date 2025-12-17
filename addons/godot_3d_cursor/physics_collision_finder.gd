class_name PhysicsCollisionFinder
## This class provides methods for detecting collisions using physics-based raycasting.
##
## This finder is used when [member Plugin3DCursor.raycast_mode] is set to
## [member Plugin3DCursor.RaycastMode.PHYSICS]. It is considered a legacy implementation
## and is unlikely to receive further updates, as
## [member Plugin3DCursor.RaycastMode.PHYSICSLESS] is now the recommended mode.


## This method computes the closest collision by sending a physics-based raycast
## from [param from] to [param to] by using the [member World3D.direct_space_state].
func get_closest_collision(from: Vector3, to: Vector3, world_3d: World3D) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	var hit: Dictionary = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	return hit
