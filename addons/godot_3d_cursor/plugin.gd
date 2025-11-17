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
## The scene used to instantiate the 3D Cursor
var cursor_scene: PackedScene
## The instance of the 3D Cursor
var cursor: Cursor3D
## The scene used to instantiate the pie menu for the 3D Cursor
var pie_menu_scene: PackedScene
## The instance of the pie menu for the 3D Cursor
var pie_menu: PieMenu
## A reference to the [EditorCommandPalette] singleton used to add
## some useful actions to the command palette such as '3D Cursor to Origin'
## or '3D Cursor to selected object' like in Blender
var command_palette: EditorCommandPalette
## The InputEvent holding the MouseButton event to trigger the
## set position function of the 3D Cursor
var input_event_set_3d_cursor: InputEventMouseButton
var input_event_show_pie_menu: InputEventKey
## The boolean that ensures the _recover_cursor function is executed once
var cursor_set: bool = false
## The instance of the Undo Redo class
var undo_redo: EditorUndoRedoManager


func _enter_tree() -> void:
	if ProjectSettings.get_setting("physics/3d/run_on_separate_thread", false):
		push_warning(
			"At this point in time the plugin 'Godot 3D Cursor' does not support the 'Run on Separate Thread' project setting (physics/3d/run_on_separate_thread)."
			+ "\n\t\tTo use this plugin:"
			+ "\n\t\t1.\tDeactivate the project setting"
			+ "\n\t\t2.\tDeactivate the plugin"
			+ "\n\t\t3.\tRestart Godot."
			+ "\n\t\t4.\tEnable the plugin again."
		)

	# Register the switching of tabs in the editor. We only want the
	# 3D Cursor functionality within the 3D tab
	connect("main_screen_changed", _on_main_scene_changed)
	# We want to place newly added Nodes that inherit [Node3D] at
	# the location of the 3D Cursor. Therefore we listen to the
	# node_added event
	get_tree().connect("node_added", _on_node_added)

	# Loading the 3D Cursor scene for later instancing
	cursor_scene = preload("res://addons/godot_3d_cursor/3d_cursor.tscn")
	pie_menu_scene = preload("res://addons/godot_3d_cursor/pie_menu.tscn")

	command_palette = EditorInterface.get_command_palette()
	# Adding the previously mentioned actions
	command_palette.add_command("3D Cursor to Origin", "3D Cursor/3D Cursor to Origin", _3d_cursor_to_origin)
	command_palette.add_command("3D Cursor to Selected Object", "3D Cursor/3D Cursor to Selected Object", _3d_cursor_to_selected_objects)
	command_palette.add_command("Selected Object to 3D Cursor", "3D Cursor/Selected Object to 3D Cursor", _selected_object_to_3d_cursor)
	# Adding the remove 3D Cursor in Scene action
	command_palette.add_command("Remove 3D Cursor from Scene", "3D Cursor/Remove 3D Cursor from Scene", _remove_3d_cursor_from_scene)
	command_palette.add_command("Toggle 3D Cursor", "3D Cursor/Toggle 3D Cursor", _toggle_3d_cursor)

	editor_viewport = EditorInterface.get_editor_viewport_3d()
	editor_camera = editor_viewport.get_camera_3d()

	# Get the reference to the UndoRedo instance of the editor
	undo_redo = get_undo_redo()

	# Instantiating the pie menu for the 3D Cursor commands
	pie_menu = pie_menu_scene.instantiate()
	pie_menu.hide()
	# Connecting the button events from the pie menu to the corresponding function
	pie_menu.connect("cursor_to_origin_pressed", _3d_cursor_to_origin)
	pie_menu.connect("cursor_to_selected_objects_pressed", _3d_cursor_to_selected_objects)
	pie_menu.connect("selected_object_to_cursor_pressed", _selected_object_to_3d_cursor)
	pie_menu.connect("remove_cursor_from_scene_pressed", _remove_3d_cursor_from_scene)
	pie_menu.connect("toggle_cursor_pressed", _toggle_3d_cursor)
	add_child(pie_menu)


	# Setting up the InputMap so that we can set the 3D Cursor
	# by Shift + Right Click
	if not InputMap.has_action("3d_cursor_set_location"):
		InputMap.add_action("3d_cursor_set_location")
		input_event_set_3d_cursor = InputEventMouseButton.new()
		input_event_set_3d_cursor.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("3d_cursor_set_location", input_event_set_3d_cursor)

	# Adding the action that shows the pie menu for the 3D Cursor commands.
	if not InputMap.has_action("3d_cursor_show_pie_menu"):
		InputMap.add_action("3d_cursor_show_pie_menu")
		input_event_show_pie_menu = InputEventKey.new()
		input_event_show_pie_menu.keycode = KEY_S
		InputMap.action_add_event("3d_cursor_show_pie_menu", input_event_show_pie_menu)



func _exit_tree() -> void:
	# Removing listeners
	disconnect("main_screen_changed", _on_main_scene_changed)
	get_tree().disconnect("node_added", _on_node_added)

	pie_menu.disconnect("cursor_to_origin_pressed", _3d_cursor_to_origin)
	pie_menu.disconnect("cursor_to_selected_objects_pressed", _3d_cursor_to_selected_objects)
	pie_menu.disconnect("selected_object_to_cursor_pressed", _selected_object_to_3d_cursor)
	pie_menu.disconnect("remove_cursor_from_scene_pressed", _remove_3d_cursor_from_scene)
	pie_menu.disconnect("toggle_cursor_pressed", _toggle_3d_cursor)

	# Removing the actions from the [EditorCommandPalette]
	command_palette.remove_command("3D Cursor/3D Cursor to Origin")
	command_palette.remove_command("3D Cursor/3D Cursor to Selected Object")
	command_palette.remove_command("3D Cursor/Selected Object to 3D Cursor")
	command_palette.remove_command("3D Cursor/Remove 3D Cursor from Scene")
	command_palette.remove_command("3D Cursor/Toggle 3D Cursor")
	command_palette = null

	# Removing the '3D Cursor set Location' action from the InputMap
	if InputMap.has_action("3d_cursor_set_location"):
		InputMap.action_erase_event("3d_cursor_set_location", input_event_set_3d_cursor)
		InputMap.erase_action("3d_cursor_set_location")

	# Removing the 'Show Pie Menu' action from the InputMap
	if InputMap.has_action("3d_cursor_show_pie_menu"):
		InputMap.action_erase_event("3d_cursor_show_pie_menu", input_event_show_pie_menu)
		InputMap.erase_action("3d_cursor_show_pie_menu")

	# Removing and freeing the helper objects
	if temp_camera != null and editor_viewport != null:
		editor_viewport.remove_child(temp_camera)
		temp_camera.queue_free()

	# Deleting the 3D Cursor
	if cursor != null:
		cursor.queue_free()
		cursor_scene = null

	# Deleting the pie menu
	if pie_menu != null:
		pie_menu.queue_free()
		pie_menu_scene = null


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

	if cursor == null or not cursor.is_inside_tree():
		return

	if Input.is_key_pressed(KEY_SHIFT) and Input.is_action_just_pressed("3d_cursor_show_pie_menu"):
		pie_menu.visible = not pie_menu.visible
		_set_visibility_toggle_label()


func _input(event: InputEvent) -> void:
	if event.is_released():
		return

	if not pie_menu.visible:
		return

	if pie_menu.hit_any_button():
		return

	if event is InputEventKey and event.keycode == KEY_S and event.is_echo():
		return

	if event is InputEventKey or event is InputEventMouseButton:
		pie_menu.hide()
		# CAUTION: Do not mess with this statement! It can render your editor
		# responseless. If it happens remove the plugin and restart the engine.
		editor_viewport.set_input_as_handled()


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

	_create_undo_redo_action(
		cursor,
		"global_position",
		Vector3.ZERO,
		"Move 3D Cursor to Origin",
	)


## Set the position of the 3D Cursor to the selected object and if multiple
## Nodes are selected to the average of the positions of all selected nodes
## that inherit [Node3D]
func _3d_cursor_to_selected_objects() -> void:
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
		_create_undo_redo_action(
			cursor,
			"global_position",
			selected_nodes.front().global_position,
			"Move 3D Cursor to selected Object",
		)
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
	_create_undo_redo_action(
		cursor,
		"global_position",
		average_position,
		"Move 3D Cursor to selected Objects",
	)
	cursor.global_position = average_position


## Set the position of the selected object that inherits [Node3D]
## to the position of the 3D Cursor. If multiple nodes are selected the first
## valid node (i.e. a node that inherits [Node3D]) will be moved to
## position of the 3D Cursor. This funcitonality is disabled if the cursor
## is not set or hidden in the scene.
func _selected_object_to_3d_cursor() -> void:
	if not _cursor_available():
		return

	# Get the selection and through this the selected nodes as an Array of Nodes
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()

	if selected_nodes.is_empty():
		return
	if selected_nodes.size() == 1 and not selected_nodes.front() is Node3D:
		return
	selected_nodes = selected_nodes.filter(func(node): return node is Node3D and not node is Cursor3D)
	if selected_nodes.is_empty():
		return

	_create_undo_redo_action(
		selected_nodes.front(),
		"global_position",
		cursor.global_position,
		"Move Object to 3D Cursor"
	)


## Disable the 3D Cursor to prevent the node placement at the position of
## the 3D Cursor.
func _toggle_3d_cursor() -> void:
	if not _cursor_available(true):
		return

	cursor.visible = not cursor.visible
	_set_visibility_toggle_label()


## Sets the correct label on the toggle visibility button in the pie menu
func _set_visibility_toggle_label() -> void:
	pie_menu.change_toggle_label(cursor.visible)


## Remove every 3D Cursor from the scene including the active one.
func _remove_3d_cursor_from_scene() -> void:
	if cursor == null:
		return

	# Remove the active 3D Cursor
	cursor.queue_free()
	cursor = null

	# Get the root nodes children to filter for old instances of [Cursor3D]
	var root_children = edited_scene_root.get_children()
	if root_children.any(func(node): return node is Cursor3D):
		# Iterate over all old instances and free them
		for old_cursor: Cursor3D in root_children.filter(func(node): return node is Cursor3D):
			old_cursor.queue_free()


## Check whether the 3D Cursor is set up and ready for use. A hidden 3D Cursor
## should also disable its functionality. Therefore this function yields false
## if the cursor is hidden in the scene
func _cursor_available(ignore_hidden = false) -> bool:
	# CAUTION: Do not mess with this statement! It can render your editor
	# responseless. If it happens remove the plugin and restart the engine.
	editor_viewport.set_input_as_handled()
	if cursor == null:
		return false
	if not cursor.is_inside_tree():
		return false
	if ignore_hidden and not cursor.is_visible_in_tree():
		return true
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

	if not cursor_set:
		_recover_cursor()

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
		edited_scene_root = _get_first_3d_root_node()

	# Either there is no Node3D in the scene or the plugin failed to locate one
	if edited_scene_root == null:
		return

	# The space state where the raycast should be performed in
	var space_state = edited_scene_root.get_world_3d().direct_space_state

	# Perform a raycast with the parameters above and store the result
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end))

	var just_created: bool = false

	# When the cursor is not yet created instantiate it, add it to the scene
	# and position it at the collision detected by the raycast
	if cursor == null:
		cursor = cursor_scene.instantiate()
		edited_scene_root.add_child(cursor)
		cursor.owner = edited_scene_root
		just_created = true

	# If the cursor is not in the node tree at this point it means that the
	# user probably deleted it. Then add it again
	if not cursor.is_inside_tree():
		edited_scene_root.add_child(cursor)
		cursor.owner = edited_scene_root
		just_created = true

	# No collision means do nothing
	if result.is_empty():
		return

	if just_created:
		# Position the 3D Cursor to the position of the collision
		cursor.global_transform.origin = result.position
		return

	# If the cursor is hidden don't set its position
	if not _cursor_available():
		return

	_create_undo_redo_action(
		cursor,
		"global_position",
		result.position,
		"Set Position for 3D Cursor"
	)


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


## This function recovers any 3D Cursor present in the scene if you reload
## the project
func _recover_cursor() -> void:
	# This boolean ensures this function is run exactly once
	cursor_set = true
	# Gets the children of the active scenes root node
	var root_children = EditorInterface.get_edited_scene_root().get_children()
	# Checks whether there are any nodes of type [Cursor3D] in the list of
	# children
	if root_children.any(func(node): return node is Cursor3D):
		# Get the first and probably only instance of [Cursor3D] and assign
		# it to the cursor variable. Now the 3D Cursor is considered recovered
		cursor = root_children.filter(func(node): return node is Cursor3D).front()


func _create_undo_redo_action(node: Node3D, property: String, value: Variant, action_name: String = "") -> void:
	if node == null or property.is_empty() or value == null:
		return

	if action_name.is_empty():
		action_name = "Set " + property + " for " + node.name

	undo_redo.create_action(action_name)
	var old_value: Variant = node.get(property)
	undo_redo.add_do_property(node, property, value)
	undo_redo.add_undo_property(node, property, old_value)
	undo_redo.commit_action()


## This function searches for the first instance of a Node3D in the sceen tree.
## If the root is not a Node3D, it will search recursively to find the Node3D
## with the shortest path.
func _get_first_3d_root_node() -> Node3D:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root is Node3D:
		return root
	var found_root: Dictionary = _search_for_3d_root(root)
	if found_root.is_empty():
		push_warning("The plugin 'Godot 3D Cursor' was unable to locate a Node3D to base its calculation upon in your scene.")
		return null
	return found_root["node"]


## This function searches recursively for Node3D through every path of nodes.
## The Node3D with the shortest path is considered the root node and will be
## returned at the end. It is important to use `Dictionary` as the return type
## instead of `Dictionary[String, Variant]` because typed Dictionaries were
## introduced in Godot 4.4 and would exclude older Godot versions that
## this plugin could support.
func _search_for_3d_root(current_node: Node, level: int = 0) -> Dictionary:
	# This Array contains the first Node3Ds of any subpath from current_node
	var results: Array[Dictionary] = []

	# We iterate through every child of the current_node
	for child in current_node.get_children():
		# If a child is already a Node3D we return it in a Dictionary along with its depth (level)
		if child is Node3D:
			return { "level": level, "node": child }
	# As we didn't leave the function early we go through the children again
	for child in current_node.get_children():
		# We invoke the method recursively with a deeper level
		var result: Dictionary = _search_for_3d_root(child, level + 1)

		# If there are Node3Ds found, we return them
		if not result.is_empty():
			results.append(result)

	# If we haven't found any Node3Ds, we return an empty Dictionary
	if results.is_empty():
		return {}

	# If we found exactly one Node3D we will return exactly this one
	if results.size() == 1:
		return results[0]

	# This value represents the index of the Node3D in results with the shortest
	# path (level). Initialized with -1 to show that nothing is found yet.
	var lowest_index: int = -1
	# This value represents the level this Node3D is found on. The bigger the
	# deeper it is i. e. more nested in the tree. We want the lowest level.
	# If two have the same level the first one is earlier in the tree, which we
	# want. Initialized with -1 to show that nothing is found yet.
	var lowest_level: int = -1

	# We go through the results with a range to keep track of the current index.
	for i in range(results.size()):
		# If the value of level from the result is lower than the lowest_level
		# this result is the better option so far.
		if results[i]["level"] < lowest_level or lowest_level == -1:
			# Reassign the lowest_index as it is the better choice.
			lowest_index = i
			# Reassign the lowest_level as it is the better choice.
			lowest_level = results[i]["level"]

	# At the end we return the Node3D with the shortest path in this instance
	# of the recursive function call.
	return results[lowest_index]
