class_name Cursor3DRaycastEngine
extends Node

## This Enum holds the values for the different modes of raycasting.
enum RaycastMode {
	## [br](Legacy) This mode uses physics-based raycasting, so the cursor can only be placed
	## on objects with a collider.[br][br]
	## The setting [code]physics/3d/run_on_separate_thread[/code] must be disabled for this
	## mode to function correctly.[br][br]
	## The [Terrain3D] plugin by [i]TokisanGames[/i] is partially supported. To enable
	## compatibility, the [param Collision Mode] of the [Terrain3D] instance must be set
	## to either [param Dynamic / Editor] or [param Full / Editor] in the inspector.[br]
	PHYSICS,
	## [br]This mode uses mesh-based raycasting, allowing the cursor to be placed on objects
	## with a mesh or on [CSGShape3D] objects that can bake a mesh.[br][br] In addition, this mode
	## supports the [Terrain3DExtension] for the [Terrain3D] plugin by [i]TokisanGames[/i].
	## [b]Note[/b] that [Terrain3D] instances must be assigned to the [i]"Terrain3D"[/i] group.
	PHYSICSLESS,
}

var plugin_context: Plugin3DCursor
## The collision finder object that searches for collisions using a mesh-based system.
var physicsless_collision_finder: PhysicslessCollisionFinder
## The collision finder object that searches for collisions using a physics-based system. (Legacy)
var physics_collision_finder: PhysicsCollisionFinder
## The currently active [enum RaycastMode] for the 3D Cursor
var raycast_mode: RaycastMode
## The Editor Viewport used to get the mouse position
var editor_viewport: SubViewport:
	get:
		return EditorInterface.get_editor_viewport_3d()
## The camera that displays what the user sees in the 3D editor tab
var editor_camera: Camera3D:
	get:
		return editor_viewport.get_camera_3d()
## The root node of the active scene
var edited_scene_root: Node3D:
	get:
		return _get_first_3d_root_node()
var true_edited_scene_root: Node:
	get:
		return EditorInterface.get_edited_scene_root()
var cursor: Cursor3D:
	get:
		return plugin_context.cursor
var input_manager: Cursor3DInputManager:
	get:
		return plugin_context.input_manager
var cursor_actions: Cursor3DActions:
	get:
		return plugin_context.cursor_actions


func _init(plugin_context: Plugin3DCursor, raycast_mode: RaycastMode = RaycastMode.PHYSICSLESS) -> void:
	if plugin_context == null:
		push_error("The Cursor3DRaycastEngine requires a valid instance of Plugin3DCursor"
			+ " and must not be null."
		)
	self.plugin_context = plugin_context
	physicsless_collision_finder = PhysicslessCollisionFinder.new()
	physics_collision_finder = PhysicsCollisionFinder.new()
	self.raycast_mode = raycast_mode
	if not check_compatibility():
		self.raycast_mode = RaycastMode.PHYSICS

	plugin_context.signal_hub.raycast_mode_changed.connect(_on_raycast_mode_changed)
	editor_viewport = EditorInterface.get_editor_viewport_3d()
	editor_camera = editor_viewport.get_camera_3d()


## Checks whether the current Godot version is high enough to determine compabtibility
## with newer [Cursor3D] features introduced in [i]Godot 3D Cursor[/i] v1.4.0+.
static func check_compatibility() -> bool:
	return Engine.get_version_info().hex >= 0x040500


func _on_raycast_mode_changed(raycast_mode: RaycastMode) -> void:
	if raycast_mode == RaycastMode.PHYSICSLESS and check_compatibility():
		self.raycast_mode = raycast_mode
		return
	self.raycast_mode = RaycastMode.PHYSICS


## This function searches for the first instance of a Node3D in the sceen tree.
## If the root is not a Node3D, it will search recursively to find the Node3D
## with the shortest path.
func _get_first_3d_root_node() -> Node3D:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		return null
	if root is Node3D:
		return root
	var nodes: Array = root.find_children("*", "Node3D", true, false)
	if nodes.is_empty():
		push_warning("The plugin 'Godot 3D Cursor' was unable to locate a Node3D to base its calculation upon in your scene.")
	root = nodes[0]
	return root


## This function returns the transform of the camera from the 3D Editor itself
func _get_editor_camera_transform() -> Transform3D:
	if editor_camera != null:
		return editor_camera.get_camera_transform()
	return Transform3D.IDENTITY


## This function uses raycasting to determine the position of the mouse click
## to set the position of the 3D Cursor. This means that it is necessary for
## the clicked on objects to have a collider the raycast can hit
func _get_click_location(create_new_cursor: bool = false, recover_cursor: bool = false) -> void:
	var editor_camera_transform = _get_editor_camera_transform()

	# if the editor_camera_transform is Transform3D.IDENTITY that means
	# that for some reason the editor_camera is null.
	if editor_camera_transform == Transform3D.IDENTITY:
		return

	# If there is no scene root set, try to get one
	if edited_scene_root == null:
		edited_scene_root = _get_first_3d_root_node()

	# Either there is no Node3D in the scene or the plugin failed to locate one
	if edited_scene_root == null:
		return

	# The space state where the raycast should be performed in
	var space_state
		# Set up the raycast parameters
	var ray_length = 1000
	# The position from where to start raycasting
	var from = editor_camera.project_ray_origin(input_manager.mouse_position)
	# The direction in which to raycast
	var dir = editor_camera.project_ray_normal(input_manager.mouse_position)
	# The point to raycast to (dependent of ray_length and camera mode i.e. perspective/orthogonal)
	var to = from + dir * (editor_camera.far if editor_camera.far > 0.0 else ray_length)
	# The variable to store the raycast hit
	var hit: Dictionary
	# Choose the collision finder depending on the raycast mode
	# Then perform a raycast with the parameters above and store the result in hit
	if raycast_mode == RaycastMode.PHYSICSLESS:
		hit = await physicsless_collision_finder.get_closest_collision(
			from, to, editor_camera
		)
	elif raycast_mode == RaycastMode.PHYSICS:
		hit = physics_collision_finder.get_closest_collision(
			from, to, edited_scene_root.get_world_3d()
		)

	# This bool indicates whether the 3D cursor is just created
	var just_created: bool = false

	var newest_cursor: Cursor3D = plugin_context.get_newest_cursor()
	if not create_new_cursor and recover_cursor and newest_cursor != null:
		plugin_context.signal_hub.cursor_recovered.emit(newest_cursor)
		cursor_actions.place_cursor(hit["position"])
		return

	# When the cursor is not yet created instantiate it, add it to the scene
	# and position it at the collision detected by the raycast
	if cursor == null or create_new_cursor:
		plugin_context.create_cursor()
		just_created = true

	# If the cursor is not in the node tree at this point it means that the
	# user probably deleted it. Then add it again
	if not cursor.is_inside_tree():
		plugin_context.add_cursor_to_tree()
		just_created = true

	# No collision means do nothing
	if hit.is_empty():
		return

	# If the cursor was just created
	if just_created:
		# Position the 3D Cursor to the position of the collision
		#cursor.global_transform.origin = result.position
		cursor.global_transform.origin = hit["position"]
	if create_new_cursor and plugin_context.active_path_3d != null:
		plugin_context.add_point_to_curve()
	if just_created:
		return

	# If the cursor is hidden don't set its position
	if not plugin_context.cursor_available():
		return

	# Make the action undoable/redoable
	cursor_actions.place_cursor(hit["position"])
