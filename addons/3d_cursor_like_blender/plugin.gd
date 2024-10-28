@tool
extends EditorPlugin


## This variable indicates whether the active tab is 3D
var is_in_3d_tab: bool = false
## The position of the mouse used to raycast into the 3D world
var mouse_position: Vector2
## The camera used for raycasting to calculate the position
## for the 3D cursor
var temp_camera: Camera3D
## The Editor Viewport used to get the mouse position
var editor_viewport: SubViewport
## The camera that displays what the user sees in the 3D editor tab
var editor_camera: Camera3D
## The root node of the active scene
var edited_scene_root: Node
## The instance of the 3D Cursor
var cursor: Cursor3D
## The scene used to instantiate the 3D Cursor
var cursor_scene: PackedScene
## A reference to the [EditorCommandPalette] singleton used to add
## some useful actions to the command palette such as '3D Cursor to Origin'
## or '3D Cursor to selected object' like in Blender
var command_palette: EditorCommandPalette
## The InputEvent holding the MouseButton event to trigger the
## set position function of the 3D Cursor
var input_event_set_3d_cursor: InputEventMouseButton


func _enter_tree() -> void:
	# Register the switching of tabs in the editor. We only want the
	# 3D Cursor functionality within the 3D tab
	connect("main_screen_changed", _on_main_scene_changed)
	# We want to place newly added Nodes that inherit [Node3D] at
	# the location of the 3D Cursor. Therefore we listen to the
	# node_added event
	get_tree().connect("node_added", _on_node_added)

	# Loading the 3D Cursor scene for later instancing
	cursor_scene = preload("res://addons/3d_cursor_like_blender/3d_cursor.tscn")

	command_palette = EditorInterface.get_command_palette()
	# Adding the previously mentioned actions
	command_palette.add_command("3D Cursor to Origin", "3D Cursor/3D Cursor to Origin", _3d_cursor_to_origin)
	command_palette.add_command("3D Cursor to selected object", "3D Cursor/3D Cursor to selected object", _3d_cursor_to_selected_object)


	editor_viewport = EditorInterface.get_editor_viewport_3d()
	editor_camera = editor_viewport.get_camera_3d()

	# Setting up the InputMap so that we can set the 3D Cursor
	# by Shift + Right Click
	if not InputMap.has_action("3d_cursor_set_location"):
		InputMap.add_action("3d_cursor_set_location")
		input_event_set_3d_cursor = InputEventMouseButton.new()
		input_event_set_3d_cursor.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("3d_cursor_set_location", input_event_set_3d_cursor)


func _exit_tree() -> void:
	# Removing listeners
	disconnect("main_screen_changed", _on_main_scene_changed)
	get_tree().disconnect("node_added", _on_node_added)

	# Removing the actions from the [EditorCommandPalette]
	command_palette.remove_command("3D Cursor/3D Cursor to Origin")
	command_palette.remove_command("3D Cursor/3D Cursor to selected object")
	command_palette = null

	# Removing the Action from the InputMap
	if InputMap.has_action("3d_cursor_set_location"):
		InputMap.action_erase_event("3d_cursor_set_location", input_event_set_3d_cursor)
		InputMap.erase_action("3d_cursor_set_location")

	# Removing and freeing the helper objects
	if temp_camera != null and editor_viewport != null:
		editor_viewport.remove_child(temp_camera)
		temp_camera.queue_free()

	# Deleting the 3D Cursor
	if cursor != null:
		cursor.queue_free()
		cursor_scene = null


func _process(delta: float) -> void:
	# Only allow setting the 3D Cursors location in 3D tab
	if not is_in_3d_tab:
		return

	# If the action is not yet set up: return
	if not InputMap.has_action("3d_cursor_set_location"):
		return

	# Set the location of the 3D Cursor
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_action_just_pressed("3d_cursor_set_location"):
		mouse_position = editor_viewport.get_mouse_position()
		_get_selection()


## Checks whether the current active tab is named '3D'
## returns true if so, otherwise false
func _on_main_scene_changed(screen_name: String) -> void:
	is_in_3d_tab = screen_name == "3D"


## Connected to the node_added event of the get_tree()
func _on_node_added(node: Node) -> void:
	if not _cursor_available():
		return
	if EditorInterface.get_edited_scene_root() != cursor.owner:
		return
	if node.name == cursor.name:
		return
	if cursor.is_ancestor_of(node):
		return
	if not node is Node3D:
		return
	# Apply the position of the new node to the 3D Cursors position if the
	# 3D cursor is available, the node is not the 3D cursor itself, the node
	# is no descendant of the 3D Cursor and the node inherits [Node3D]
	node.global_position = cursor.global_position


## Set the postion of the 3D Cursor to the origin (or [Vector3.ZERO])
func _3d_cursor_to_origin() -> void:
	if not _cursor_available():
		return

	cursor.global_position = Vector3.ZERO


## Set the position of the 3D Cursor to the selected object and if multiple
## Nodes are selected to the average of the positions of all selected nodes
## that inherit [Node3D]
func _3d_cursor_to_selected_object() -> void:
	if not _cursor_available():
		return

	# Get the selection and through this the selected nodes as an Array of Nodes
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()

	if selected_nodes.is_empty():
		return
	if selected_nodes.size() == 1 and not selected_nodes.front() is Node3D:
		return

	# If only one Node is selected and it inherits Node3D set the position
	# of the 3D Cursor to its position
	if selected_nodes.size() == 1:
		cursor.global_position = selected_nodes.front().global_position
		return

	# Introduce a count variable to keep track of the amount of valid positions
	# to calculate the average position later
	var count = 0
	var position_sum: Vector3 = Vector3.ZERO

	for node in selected_nodes:
		if not (node is Node3D or node is Cursor3D):
			continue

		# If the node is a valid object increment count and add the position
		# to position_sum
		count += 1
		position_sum += node.global_position

	if count == 0:
		return

	# Calculate the average position for multiple selected Nodes and set
	# the 3D Cursor to this position
	var average_position = position_sum / count
	cursor.global_position = average_position


## Check whether the 3D Cursor is set up and ready for use. A hidden 3D Cursor
## should also disable its functionality. Therefore this function yields false
## if the cursor is hidden in the scene
func _cursor_available() -> bool:
	if cursor == null:
		return false
	if not cursor.is_inside_tree():
		return false
	if not cursor.is_visible_in_tree():
		return false
	return true


## This function uses raycasting to determine the position of the mouse click
## to set the position of the 3D Cursor. This means that it is necessary for
## the clicked on objects to have a collider the raycast can hit
func _get_selection() -> void:
	# If the scene is switched stop
	if edited_scene_root != null and edited_scene_root != EditorInterface.get_edited_scene_root() and cursor != null:
		# Reset scene root, viewport and camera for new scene
		edited_scene_root = null
		editor_viewport = EditorInterface.get_editor_viewport_3d()
		editor_camera = editor_viewport.get_camera_3d()

		# Clear the 3D Cursor on the old screen.
		cursor.queue_free()
		cursor = null

	if temp_camera == null:
		# Set up the temp_camera to resemble the one of the 3D Viewport
		_create_temp_camera()

	# Get the transform of the camera from the 3D Viewport
	var editor_camera_transform = _get_editor_camera_transform()

	# Position the temp_camera so that it is exactly where the 3D Viewport
	# camera is located
	temp_camera.global_transform = editor_camera_transform

	# if the editor_camera_transform is Transform3D.IDENTITY that means
	# that for some reason the editor_camera is null.
	if editor_camera_transform == Transform3D.IDENTITY:
		return

	# Set up the raycast parameters
	var ray_origin = temp_camera.project_ray_origin(mouse_position)
	var ray_end = temp_camera.project_position(mouse_position, 1000)
	var ray_length = 1000

	if edited_scene_root == null:
		edited_scene_root = EditorInterface.get_edited_scene_root()

	# The space state where the raycast should be performed in
	var space_state = edited_scene_root.get_world_3d().direct_space_state

	# Perform a raycast with the parameters above and store the result
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end))

	# When the cursor is not yet created instantiate it, add it to the scene
	# and position it at the collision detected by the raycast
	if cursor == null:
		cursor = cursor_scene.instantiate()
		edited_scene_root.add_child(cursor)
		cursor.owner = edited_scene_root

	# If the cursor is not in the node tree at this point it means that the
	# user probably deleted it. Then add it again
	if not cursor.is_inside_tree():
		edited_scene_root.add_child(cursor)
		cursor.owner = edited_scene_root

	# No collision means do nothing
	if result.is_empty():
		return

	# Position the 3D Cursor to the position of the collision
	cursor.global_transform.origin = result.position


## This function creates the temp_camera and sets it up so that it resembles
## the camera from 3D Tab itself
func _create_temp_camera() -> void:
	temp_camera = Camera3D.new()
	temp_camera.hide()

	# Add the temp_camera to the editor_viewport so that we can perform raycasts
	# later on
	editor_viewport.add_child(temp_camera)

	# These are the most important settings the temp_camera needs to copy
	# from the editor_camera so that their image is congruent
	temp_camera.fov = editor_camera.fov
	temp_camera.near = editor_camera.near
	temp_camera.far = editor_camera.far


## This function returns the transform of the camera from the 3D Editor itself
func _get_editor_camera_transform() -> Transform3D:
	if editor_camera != null:
		return editor_camera.get_camera_transform()
	return Transform3D.IDENTITY
