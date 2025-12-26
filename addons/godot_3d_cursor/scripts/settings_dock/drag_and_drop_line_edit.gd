@tool
class_name ActiveCursorLineEdit
## This class implements the LineEdit used to display the currently active [Cursor3D] and
## provides drag-and-drop functionality.
##
## It inherits from [LineEdit] and implements [member Control._can_drop_data] as well as
## [member Control._drop_data]. This allows users to drag [Cursor3D] instances onto the
## control, similar to the behavior found in the Inspector.[br][br]
##
## Clicking the empty [ActiveCursorLineEdit] with the left mouse button opens a node
## selector window. If a [Cursor3D] instance is already assigned, clicking the
## [ActiveCursorLineEdit] will select that instance in the editor.[br][br]
##
## Double-clicking the [ActiveCursorLineEdit] selects the [Cursor3D] instance and focuses
## the editor camera on it. Holding [code]CTRL[/code] while clicking will additionally move
## the camera toward the instance. Clicking while holding [code]ALT[/code] opens the node
## selector window again.
extends LineEdit

## The reference to the plugin core.
var plugin_context: Plugin3DCursor


## Sets up the [member ActiveCursorLineEdit.plugin_context]
func setup(plugin_context: Plugin3DCursor) -> void:
	self.plugin_context = plugin_context


func _gui_input(event: InputEvent) -> void:
	# We check whether the input is mouse click event
	if not event is InputEventMouseButton:
		return
	# Then we check if the input is a left mouse click
	if event.button_index != MouseButton.MOUSE_BUTTON_LEFT:
		return
	if not event.is_pressed():
		return

	# Emits a signal indicating that the ActiveCursorLineEdit was clicked,
	# including whether the click was a double-click.
	plugin_context.signal_hub.active_cursor_line_edit_clicked.emit(event.double_click)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Data has to contain a dictionary
	if not data is Dictionary:
		return false

	# Data has to contain a "nodes" key
	if not data.has("nodes"):
		return false

	# The Array behind the "nodes" key may only hold one item
	if data["nodes"].size() > 1:
		return false

	# The node has to be a Cursor3D
	if not get_node(data["nodes"][0]) is Cursor3D:
		return false

	# We accept the dragged node
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Only one node is allowed at a time
	if data["nodes"].size() != 1:
		return

	# Emits a signal indicating that a Cursor3D instance was dropped on the
	# ActiveCursorLineEdit, including the NodePath to the instance.
	plugin_context.signal_hub.active_cursor_line_edit_data_dropped.emit(data["nodes"][0])
