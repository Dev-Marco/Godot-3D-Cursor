@tool
class_name DragAndDropLineEdit
extends LineEdit

signal cursor_selected(cursor: Cursor3D)
signal cursor_deselected

## The [Cursor3D] instance that is set as active in the settings dock.
var _linked_node: Cursor3D

@onready var terrain_3d_instances: HBoxContainer = $"../../../Terrain3DInstances"


func _gui_input(event: InputEvent) -> void:
	# First, we check if we check for a left mouse click
	if not event is InputEventMouseButton:
		return
	if event.button_index != MouseButton.MOUSE_BUTTON_LEFT:
		return
	if not event.is_pressed():
		return

	# If the CTRL Key is pressed while clicking on the LineEdit we zoom in to
	# the selected Cursor
	if Input.is_key_pressed(KEY_CTRL):
		_select_linked_node_in_editor(true)
		return

	if _linked_node == null or Input.is_key_pressed(KEY_ALT):
		EditorInterface.popup_node_selector(_assign_node, ["Cursor3D"])

	# If the LineEdit is clicked without CTRL we just look towards the Cursor
	_select_linked_node_in_editor()


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

	_assign_node(data["nodes"][0])


func _assign_node(node_path: NodePath):
	if node_path == null or node_path.is_empty():
		return
	# Get the node from the NodePath
	var cursor: Cursor3D = EditorInterface.get_edited_scene_root().get_node_or_null(node_path)
	if cursor == null:
		return
	# We set the LineEdit's text to the name of the Cursor3D from data
	text = cursor.name
	# We save the reference to the Cursor3D instance itself
	_linked_node = cursor
	cursor_selected.emit(cursor)


## Selectes
func _select_linked_node_in_editor(ctrl_down: bool = false) -> void:
	if _linked_node == null:
		return
	var editor_selection: EditorSelection = EditorInterface.get_selection()
	editor_selection.clear()
	editor_selection.add_node(_linked_node)
	_focus_selection(ctrl_down)


func _focus_selection(zoom_to: bool = false) -> void:
	var editor_camera: Camera3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	if editor_camera == null or _linked_node == null:
		return

	editor_camera.look_at(_linked_node.global_position)

	if zoom_to:
		var distance: float = 30.0
		var dir: Vector3 = (_linked_node.global_position - editor_camera.global_position).normalized()
		var dist_to = _linked_node.global_position.distance_to(editor_camera.global_position)
		var target_position: Vector3 = editor_camera.global_position + (dist_to - distance) * dir
		var tween: Tween = editor_camera.create_tween()
		var tween_duration: float = 0.25
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(editor_camera, "global_position", target_position, tween_duration)


func _on_clear_button_pressed() -> void:
	clear()
	_linked_node = null
	cursor_deselected.emit()


func _on_deselect_button_pressed() -> void:
	if _linked_node == null:
		return
	var editor_selection = EditorInterface.get_selection()
	if not _linked_node in editor_selection.get_selected_nodes():
		return
	editor_selection.remove_node(_linked_node)


func _on_check_box_toggled(toggled_on: bool) -> void:
	terrain_3d_instances.visible = toggled_on


func _on_cursor_created(cursor: Cursor3D) -> void:
	_linked_node = cursor
	text = cursor.name


func _on_cursor_deleted(name: String) -> void:
	_linked_node = null
	if _linked_node == null:
		clear()
