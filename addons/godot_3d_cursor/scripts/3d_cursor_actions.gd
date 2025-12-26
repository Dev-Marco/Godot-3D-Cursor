class_name Cursor3DActions
extends Node

var plugin_context: Plugin3DCursor
var undo_redo: Cursor3DUndoRedoManager


func _init(plugin_context: Plugin3DCursor, undo_redo: Cursor3DUndoRedoManager) -> void:
	if plugin_context == null:
		push_error("The Cursor3DActions requires a valid instance of Plugin3DCursor and must not be null.")
	if undo_redo == null:
		push_error("The Cursor3DActions requires a valid instance of Cursor3DUndoRedoManager and must not be null.")

	self.plugin_context = plugin_context
	self.undo_redo = undo_redo

	plugin_context.signal_hub.cursor_to_origin.connect(cursor_to_origin)
	plugin_context.signal_hub.cursor_to_selected_objects.connect(cursor_to_selected_objects)
	plugin_context.signal_hub.selected_object_to_cursor.connect(selected_object_to_cursor)
	plugin_context.signal_hub.toggle_cursor.connect(toggle_cursor)
	plugin_context.signal_hub.remove_active_cursor_from_scene.connect(remove_active_cursor_from_scene)
	plugin_context.signal_hub.remove_all_cursors_from_scene.connect(remove_all_cursors_from_scene)
	plugin_context.signal_hub.move_active_cursor_to.connect(move_active_cursor_to)


func place_cursor(position: Vector3) -> void:
	if plugin_context.cursor == null:
		return

	undo_redo.add_action(
		plugin_context.cursor,
		"global_position",
		position,
		"Set Position for 3D Cursor"
	)


## Set the postion of the 3D Cursor to the origin (or [Vector3.ZERO])
func cursor_to_origin() -> void:
	var cursor: Cursor3D = plugin_context.available_cursor()
	if cursor == null:
		return

	undo_redo.add_action(
		cursor,
		"global_position",
		Vector3.ZERO,
		"Move 3D Cursor to Origin",
	)


## Set the position of the 3D Cursor to the selected object and if multiple
## Nodes are selected to the average of the positions of all selected nodes
## that inherit [Node3D]
func cursor_to_selected_objects() -> void:
	var cursor: Cursor3D = plugin_context.available_cursor()
	if cursor == null:
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
		undo_redo.add_action(
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
	undo_redo.add_action(
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
func selected_object_to_cursor() -> void:
	var cursor: Cursor3D = plugin_context.available_cursor()
	if cursor == null:
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

	undo_redo.add_action(
		selected_nodes.front(),
		"global_position",
		cursor.global_position,
		"Move Object to 3D Cursor"
	)


## Disable the 3D Cursor to prevent the node placement at the position of
## the 3D Cursor.
func toggle_cursor() -> void:
	var cursor: Cursor3D = plugin_context.available_cursor(true)
	if cursor == null:
		return

	cursor.visible = not cursor.visible
	plugin_context.pie_menu.set_visibility_toggle_label()
	plugin_context.settings_dock.set_toggle_cursor_button_label()


## Remove the active 3D Cursor from the scene.
func remove_active_cursor_from_scene() -> void:
	if plugin_context.cursor == null:
		return
	plugin_context.signal_hub.active_cursor_deleted.emit()
	plugin_context.cursor.queue_free()
	plugin_context.unset_cursor()
	if plugin_context.get_all_cursors().size() == 1:
		plugin_context.cursor_counter.get_or_add(plugin_context.current_scene_path, 0)
		plugin_context.cursor_counter[plugin_context.current_scene_path] = 0


## Remove every 3D Cursor from the scene including the active one.
func remove_all_cursors_from_scene() -> void:
	var cursors: Array[Cursor3D]
	cursors.assign(plugin_context.get_all_cursors())
	if cursors.is_empty():
		return
	for cursor: Cursor3D in cursors:
		cursor.queue_free()
	plugin_context.unset_cursor()
	plugin_context.cursor_counter.get_or_add(plugin_context.current_scene_path, 0)
	plugin_context.cursor_counter[plugin_context.current_scene_path] = 0


func move_active_cursor_to(position: Vector3) -> void:
	place_cursor(position)
