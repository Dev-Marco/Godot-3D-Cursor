@tool
class_name Cursor3DInputManager
extends Node

const INPUT_ACTION_CURSOR_SET_LOCATION: String = "3d_cursor_set_location"
const INPUT_ACTION_SHOW_PIE_MENU: String = "3d_cursor_show_pie_menu"

var plugin_context: Plugin3DCursor
## The InputEvent holding the MouseButton event to trigger the
## set position function of the 3D Cursor
var input_event_set_3d_cursor: InputEventMouseButton
var input_event_show_pie_menu: InputEventKey
## The position of the mouse used to raycast into the 3D world
var mouse_position: Vector2
var raycast_engine: Cursor3DRaycastEngine:
	get:
		return plugin_context.raycast_engine
var cursor: Cursor3D:
	get:
		return plugin_context.cursor
var pie_menu: PieMenu:
	get:
		return plugin_context.pie_menu


func _init(plugin_context: Plugin3DCursor) -> void:
	if plugin_context == null:
		push_error("The Cursor3DInputMapManager requires a valid instance of Plugin3DCursor"
			+ " and must not be null."
		)

	self.plugin_context = plugin_context
	# Setting up the InputMap so that we can set the 3D Cursor
	# by Shift + Right Click
	if not InputMap.has_action(INPUT_ACTION_CURSOR_SET_LOCATION):
		InputMap.add_action(INPUT_ACTION_CURSOR_SET_LOCATION)
		input_event_set_3d_cursor = InputEventMouseButton.new()
		input_event_set_3d_cursor.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(INPUT_ACTION_CURSOR_SET_LOCATION, input_event_set_3d_cursor)

	# Adding the action that shows the pie menu for the 3D Cursor commands.
	if not InputMap.has_action(INPUT_ACTION_SHOW_PIE_MENU):
		InputMap.add_action(INPUT_ACTION_SHOW_PIE_MENU)
		input_event_show_pie_menu = InputEventKey.new()
		input_event_show_pie_menu.keycode = KEY_S
		InputMap.action_add_event(INPUT_ACTION_SHOW_PIE_MENU, input_event_show_pie_menu)


func _process(delta: float) -> void:
	# If the action is not yet set up: return
	if not InputMap.has_action(INPUT_ACTION_CURSOR_SET_LOCATION):
		return

	# Set the location of the 3D Cursor
	if not Input.is_key_pressed(KEY_SHIFT):
		return

	# Only allow setting the 3D Cursors location in 3D tab
	if not plugin_context.is_in_3d_tab():
		return

	if Input.is_action_just_pressed(INPUT_ACTION_CURSOR_SET_LOCATION):
		mouse_position = raycast_engine.editor_viewport.get_mouse_position()
		raycast_engine._get_click_location(
			Input.is_key_pressed(KEY_CTRL),
			Input.is_key_pressed(KEY_ALT)
		)


	if cursor == null or not cursor.is_inside_tree():
		return

	if Input.is_action_just_pressed(INPUT_ACTION_SHOW_PIE_MENU):
		pie_menu.display()


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
		raycast_engine.editor_viewport.set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_cleanup()


func _cleanup() -> void:
	# Removing the '3D Cursor set Location' action from the InputMap
	if InputMap.has_action("3d_cursor_set_location"):
		InputMap.action_erase_event("3d_cursor_set_location", input_event_set_3d_cursor)
		InputMap.erase_action("3d_cursor_set_location")

	# Removing the 'Show Pie Menu' action from the InputMap
	if InputMap.has_action("3d_cursor_show_pie_menu"):
		InputMap.action_erase_event("3d_cursor_show_pie_menu", input_event_show_pie_menu)
		InputMap.erase_action("3d_cursor_show_pie_menu")
