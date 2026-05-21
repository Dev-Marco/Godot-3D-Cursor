@tool
class_name Cursor3DInputManager
extends Node

var plugin_context: Plugin3DCursor
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


func _input(event: InputEvent) -> void:
	if not plugin_context.is_in_3d_tab():
		return
	if event.is_released():
		return

	var editor_settings: EditorSettings = EditorInterface.get_editor_settings()
	mouse_position = raycast_engine.editor_viewport.get_mouse_position()
	if event.is_pressed() and editor_settings.is_shortcut(
		plugin_context.shortcut_manager.shortcut_path + "Set 3D Cursor location", event
	):
			raycast_engine._get_click_location(false, false)
			return
	if event.is_pressed() and editor_settings.is_shortcut(
		plugin_context.shortcut_manager.shortcut_path + "Create new 3D Cursor", event):
		raycast_engine._get_click_location(true, false)
		return
	if event.is_pressed() and editor_settings.is_shortcut(
		plugin_context.shortcut_manager.shortcut_path + "Recover 3D Cursor", event
	):
		raycast_engine._get_click_location(false, true)

	if pie_menu.hit_any_button():
		return
	if cursor == null or not cursor.is_inside_tree():
		return

	if editor_settings.is_shortcut(plugin_context.shortcut_manager.shortcut_path + "Show Pie Menu", event):
		pie_menu.display()
		return
	if (event is InputEventKey or event is InputEventMouseButton) and pie_menu.visible:
		pie_menu.hide()
		# CAUTION: Do not mess with this statement! It can render your editor
		# responseless. If it happens remove the plugin and restart the engine.
		raycast_engine.editor_viewport.set_input_as_handled()
