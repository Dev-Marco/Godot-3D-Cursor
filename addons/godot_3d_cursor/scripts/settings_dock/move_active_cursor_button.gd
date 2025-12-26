@tool
class_name MoveActiveCursorButton
## This class implements a special button that accepts drop targets and moves the
## active [Cursor3D] to the dropped position. The target position can be
## seen below the button when a valid node or property is dragged over it.[br][br][br]
##
## Users can activate the button in two ways:[br][br]
## 1) Press the button to open a node selector and pick any node in the current scene
##    that inherits from [Node3D].[br][br]
##    Note: Due to engine limitations, the active [Cursor3D] instance may be selectable,
##    but it will be ignored.[br][br]
## 2) Drag and drop a supported target (node or property) onto the button to apply the
##    action to the currently active [Cursor3D].[br][br][br]
##
## Supported drop targets:[br][br]
## - Any node that inherits from [Node3D].[br][br][br]
##
## Supported inspector properties (only the first element is used for packed arrays):[br][br]
## - [PackedVector2Array], [PackedVector3Array], [PackedVector4Array][br][br]
## - [Transform2D], [Transform3D][br][br]
## - [Vector2], [Vector2i][br][br]
##   Default mapping: x -> x, y -> y, 0 -> z[br][br]
##   Hold [code]SHIFT[/code] while dragging to use: x -> x, 0 -> y, y -> z[br][br]
## - [Vector3], [Vector3i][br][br]
##   Mapping: x -> x, y -> y, z -> z[br][br]
## - [Vector4], [Vector4i][br][br]
##   Mapping: x -> x, y -> y, z -> z (w is discarded)[br][br][br]
##
## Special case: A dictionary can be dropped if it contains at least the keys
## [code]x[/code], [code]y[/code], and [code]z[/code] (case-insensitive), each mapping to
## either a [float] or an [int]. The button will convert these fields into a [Vector3]
## internally.
extends Button

## The reference to the plugin core.
var plugin_context: Plugin3DCursor
## This holds the potential dictionary that can be dropped.
var dragged_dict: Dictionary = {}
## A wrapper for [MoveActionCoordinates] accessed via
## [member MoveActiveCursorButton.plugin_context]
var move_action_coordinates: MoveActionCoordinates:
	get:
		return plugin_context.settings_dock.move_action_coordinates


## Sets up the [member MoveActiveCursorButton.plugin_context] and connects
## a signal that shows the expected target coordinates of dragged elements.
func setup(plugin_context: Plugin3DCursor) -> void:
	self.plugin_context = plugin_context
	# When the mouse leaves the button the coordinate preview will be hidden.
	mouse_exited.connect(
		func(): move_action_coordinates.visible = false
	)


func _input(event: InputEvent) -> void:
	# When SHIFT is pressed we create a fake mouse movement to get Godot to
	# update the coordinate preview without moving the mouse.
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		var fake_move: InputEventMouseMotion = InputEventMouseMotion.new()
		fake_move.position = get_local_mouse_position()
		fake_move.global_position = get_global_mouse_position()
		Input.parse_input_event(fake_move)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Data has to be a Dictionary
	if not data is Dictionary:
		return false
	# Only object properties and nodes are allowed types.
	if not data["type"] in ["obj_property", "nodes"]:
		return false
	# value is a Variant to ensure it can hold both types.
	var value: Variant
	# Extract the dragged data.
	if data["type"] == "obj_property":
		value = data["value"]
	if data["type"] == "nodes":
		value = EditorInterface.get_edited_scene_root().get_node_or_null(data["nodes"][0])
	# Check the extracted data for validity. If it is valid, show the coordinate preview.
	if is_valid_drop_type(value):
		move_action_coordinates.visible = true
		return true

	# If the data is not valid hide the coordinate preview.
	move_action_coordinates.visible = false
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Signal that valid data has been dropped and include it.
	plugin_context.signal_hub.move_active_cursor_to.emit(move_action_coordinates.coordinates)


## Ensures that the dragged data is of a supported type, or (in the case of a
## [Dictionary]) that it is set up correctly. Extracted coordinates are stored via
## [member MoveActiveCursorButton.set_coordinates] and shown in the coordinate preview
## displayed below the button.
func is_valid_drop_type(value: Variant) -> bool:
	# Check if it is a Dictionary and valid. Then store the components in
	# dragged_dict.
	if value is Dictionary and is_valid_dictionary(value):
		set_coordinates(
			dragged_dict.get("x", 0),
			dragged_dict.get("y", 0),
			dragged_dict.get("z", 0)
		)
		return true
	if value is PackedVector2Array and not value.is_empty():
		set_coordinates(value[0].x, value[0].y, 0, Input.is_key_pressed(KEY_SHIFT))
		return true
	if value is PackedVector3Array and not value.is_empty():
		set_coordinates(value[0].x, value[0].y, value[0].z)
		return true
	# [COMPATIBILITY WITH 4.2]
	# if value is PackedVector4Array and not value.is_empty():
	if type_string(typeof(value)) == "PackedVector4Array" and not value.is_empty():
		set_coordinates(value[0].x, value[0].y, value[0].z)
		return true
	if value is Transform2D:
		set_coordinates(value.origin.x, value.origin.y, 0, Input.is_key_pressed(KEY_SHIFT))
		return true
	if value is Transform3D:
		set_coordinates(value.origin.x, value.origin.y, value.origin.z)
		return true
	if value is Vector2 or value is Vector2i:
		set_coordinates(value.x, value.y, 0, Input.is_key_pressed(KEY_SHIFT))
		return true
	if value is Vector3 or value is Vector3i:
		set_coordinates(value.x, value.y, value.z)
		return true
	if value is Vector4 or value is Vector4i:
		set_coordinates(value.x, value.y, value.z)
		return true
	# Even though Node3Ds are allowed the active cursor itself is no valid target.
	if value is Node3D and value == plugin_context.cursor:
		return false
	if value is Node3D:
		var p: Vector3 = value.global_position
		set_coordinates(p.x, p.y, p.z)
		return true
	return false


## Ensures the dragged dictionary is set up correctly.
func is_valid_dictionary(dict: Dictionary) -> bool:
	if dict.size() != 3:
		return false
	var x_present: bool = false
	var y_present: bool = false
	var z_present: bool = false
	for key in dict.keys():
		if key in ["x", "X"]:
			x_present = true
			dragged_dict[key.to_lower()] = dict[key]
			continue
		if key in ["y", "Y"]:
			y_present = true
			dragged_dict[key.to_lower()] = dict[key]
			continue
		if key in ["z", "Z"]:
			z_present = true
			dragged_dict[key.to_lower()] = dict[key]
			continue
	if not (x_present and y_present and z_present):
		return false

	for value in dict.values():
		if not (value is int or value is float):
			return false
	return true


## A wrapper around [member MoveActionCoordinates.set_coordinates]. If a modifier
## key (e.g. [code]SHIFT[/code]) is pressed, the coordinate mapping is adjusted for
## applicable types.
func set_coordinates(x: float, y: float, z: float, modifier_pressed: bool = false) -> void:
	if not modifier_pressed:
		move_action_coordinates.set_coordinates(x, y, z)
		return
	move_action_coordinates.set_coordinates(x, z, y)
