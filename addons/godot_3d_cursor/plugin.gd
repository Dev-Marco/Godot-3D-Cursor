@tool

class_name Plugin3DCursor
extends EditorPlugin
## This class implements a major part of the [i]Godot 3D Cursor[/i] plugin.
##
## It uses the [Cursor3D] class to visually display the [i]3D Cursor[/i] within a scene.
## When installed and enabled, users can place a [i]3D Cursor[/i] by pressing
## [code]Shift + Right Click[/code] on any mesh-based object in the scene.
## Currently, the only officially supported third-party plugin is [Terrain3D]
## by [i]TokisanGames[/i]. For additional third-party support, please refer to the
## [url=https://github.com/Dev-Marco/Godot-3D-Cursor]GitHub repository[/url] and open an issue.

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


## This variable indicates whether the active tab is 3D
var is_in_3d_tab: bool = false
## The position of the mouse used to raycast into the 3D world
var mouse_position: Vector2
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
## The collision finder object that searches for collisions using a mesh-based system.
var physicsless_collision_finder: PhysicslessCollisionFinder
## The collision finder object that searches for collisions using a physics-based system. (Legacy)
var physics_collision_finder: PhysicsCollisionFinder
## The currently active [enum RaycastMode] for the 3D Cursor
var raycast_mode: RaycastMode = RaycastMode.PHYSICSLESS


func _enter_tree() -> void:
	_provide_3d_cursor_warnings()
	_setup_editor_events()
	_preload_3d_cursor_components()
	_setup_command_palette()
	_setup_necessary_editor_components()
	_setup_pie_menu()
	_setup_input_map_actions()


func _exit_tree() -> void:
	_disconnect_editor_events()
	_disconnect_pie_menu_events()
	_remove_command_palette_actions()
	_remove_input_map_actions()
	_free_3d_cursor()
	_free_pie_menu()


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
		_get_click_location()

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


### --------------------------  Setup Functions  --------------------------- ###

## This function sets up all warnings connected to the 3D Cursor.
func _provide_3d_cursor_warnings():
	if not _check_compatibility():
		push_warning(
			"Godot 3D Cursor 1.4.0 requires features introduced in Godot 4.5. "
		 	+ "The plugin has reverted to legacy physics-based raycasting due to "
			+ "missing engine functionality.\n\n"
			+ "Upgrade to Godot 4.5 or newer to enable the full feature set."
		)


## This function sets up all events necessary for the 3D Cursor to work correctly.
func _setup_editor_events():
	# Register the switching of tabs in the editor. We only want the
	# 3D Cursor functionality within the 3D tab
	connect("main_screen_changed", _on_main_screen_changed)
	# We want to place newly added Nodes that inherit [Node3D] at
	# the location of the 3D Cursor. Therefore we listen to the
	# node_added event
	get_tree().connect("node_added", _on_node_added)


## This function preloads every scene for the 3D Cursor.
func _preload_3d_cursor_components():
	# Loading the 3D Cursor scene for later instancing
	cursor_scene = preload("res://addons/godot_3d_cursor/3d_cursor.tscn")
	pie_menu_scene = preload("res://addons/godot_3d_cursor/pie_menu.tscn")


## This function sets up every 3D Cursor action for the command palette.
func _setup_command_palette():
	command_palette = EditorInterface.get_command_palette()
	# Adding the previously mentioned actions
	command_palette.add_command("3D Cursor to Origin", "3D Cursor/3D Cursor to Origin", _3d_cursor_to_origin)
	command_palette.add_command("3D Cursor to Selected Object", "3D Cursor/3D Cursor to Selected Object", _3d_cursor_to_selected_objects)
	command_palette.add_command("Selected Object to 3D Cursor", "3D Cursor/Selected Object to 3D Cursor", _selected_object_to_3d_cursor)
	# Adding the remove 3D Cursor in Scene action
	command_palette.add_command("Remove 3D Cursor from Scene", "3D Cursor/Remove 3D Cursor from Scene", _remove_3d_cursor_from_scene)
	command_palette.add_command("Toggle 3D Cursor", "3D Cursor/Toggle 3D Cursor", _toggle_3d_cursor)


func _setup_necessary_editor_components():
	editor_viewport = EditorInterface.get_editor_viewport_3d()
	editor_camera = editor_viewport.get_camera_3d()

	# Get the reference to the UndoRedo instance of the editor
	undo_redo = get_undo_redo()
	physicsless_collision_finder = PhysicslessCollisionFinder.new()
	physics_collision_finder = PhysicsCollisionFinder.new()


## This function sets up the pie menu for the 3D Cursor.
func _setup_pie_menu():
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


## This function sets up the input map actions for the 3D Cursor.
func _setup_input_map_actions():
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


### --------------------------  Remove Functions  -------------------------- ###

## This method disconnects the editor events.
func _disconnect_editor_events():
	# Removing listeners
	disconnect("main_screen_changed", _on_main_screen_changed)
	get_tree().disconnect("node_added", _on_node_added)


## This method disconnects the events from the pie menu buttons.
func _disconnect_pie_menu_events():
	pie_menu.disconnect("cursor_to_origin_pressed", _3d_cursor_to_origin)
	pie_menu.disconnect("cursor_to_selected_objects_pressed", _3d_cursor_to_selected_objects)
	pie_menu.disconnect("selected_object_to_cursor_pressed", _selected_object_to_3d_cursor)
	pie_menu.disconnect("remove_cursor_from_scene_pressed", _remove_3d_cursor_from_scene)
	pie_menu.disconnect("toggle_cursor_pressed", _toggle_3d_cursor)


## This method removes the actions from the command palette. It'll be invoked by
## [code]_exit_tree[/code] which in turn will indirectly be invokes by disabling the plugin.
func _remove_command_palette_actions():
	# Removing the actions from the [EditorCommandPalette]
	command_palette.remove_command("3D Cursor/3D Cursor to Origin")
	command_palette.remove_command("3D Cursor/3D Cursor to Selected Object")
	command_palette.remove_command("3D Cursor/Selected Object to 3D Cursor")
	command_palette.remove_command("3D Cursor/Remove 3D Cursor from Scene")
	command_palette.remove_command("3D Cursor/Toggle 3D Cursor")
	command_palette = null


## This method removes the input map actions. It'll be invoked by [code]_exit_tree[/code]
## which in turn will indirectly be invokes by disabling the plugin.
func _remove_input_map_actions():
	# Removing the '3D Cursor set Location' action from the InputMap
	if InputMap.has_action("3d_cursor_set_location"):
		InputMap.action_erase_event("3d_cursor_set_location", input_event_set_3d_cursor)
		InputMap.erase_action("3d_cursor_set_location")

	# Removing the 'Show Pie Menu' action from the InputMap
	if InputMap.has_action("3d_cursor_show_pie_menu"):
		InputMap.action_erase_event("3d_cursor_show_pie_menu", input_event_show_pie_menu)
		InputMap.erase_action("3d_cursor_show_pie_menu")


## This method will free the cursor and remove the reference to the [Cursor3D] scene.
func _free_3d_cursor():
	# Deleting the 3D Cursor
	if cursor != null:
		cursor.queue_free()
		cursor_scene = null


## This method will free the pie menu and remove the reference to the [PieMenu] scene.
func _free_pie_menu():
	# Deleting the pie menu
	if pie_menu != null:
		pie_menu.queue_free()
		pie_menu_scene = null


### --------------------------  Editor Bindings  --------------------------- ###

## Checks whether the current active tab is named '3D'
## returns true if so, otherwise false
func _on_main_screen_changed(screen_name: String) -> void:
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


### -------------------------  3D Cursor Actions  -------------------------- ###

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
func _get_click_location() -> void:
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

	# Get the transform of the camera from the 3D Viewport
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
	var from = editor_camera.project_ray_origin(mouse_position)
	# The direction in which to raycast
	var dir = editor_camera.project_ray_normal(mouse_position)
	# The point to raycast to (dependent of ray_length and camera mode i.e. perspective/orthogonal)
	var to = from + dir * (editor_camera.far if editor_camera.far > 0.0 else ray_length)
	# The variable to store the raycast hit
	var hit: Dictionary

	# Choose the collision finder depending on the raycast mode
	# Then perform a raycast with the parameters above and store the result in hit
	if raycast_mode == RaycastMode.PHYSICSLESS:
		hit = await physicsless_collision_finder.get_closest_collision(from, to, editor_camera)
	elif raycast_mode == RaycastMode.PHYSICS:
		hit = physics_collision_finder.get_closest_collision(from, to, edited_scene_root.get_world_3d())

	# This bool indicates whether the 3D cursor is just created
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
	if hit.is_empty():
		return

	# If the cursor was just created
	if just_created:
		# Position the 3D Cursor to the position of the collision
		#cursor.global_transform.origin = result.position
		cursor.global_transform.origin = hit["position"]
		return

	# If the cursor is hidden don't set its position
	if not _cursor_available():
		return

	# Make the action undoable/redoable
	_create_undo_redo_action(
		cursor,
		"global_position",
		#result.position,
		hit["position"],
		"Set Position for 3D Cursor"
	)


### ------------------------------  Utility  ------------------------------- ###

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


func  _check_compatibility() -> bool:
	if not CSGBox3D.new().has_method("bake_static_mesh"):
		raycast_mode = RaycastMode.PHYSICS
		return false
	if not TriangleMesh.new().has_method("create_from_faces"):
		raycast_mode = RaycastMode.PHYSICS
		return false
	return true
