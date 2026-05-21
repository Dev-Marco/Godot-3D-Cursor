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
var shortcut_manager: Cursor3DShortcutManager:
	get:
		return plugin_context.shortcut_manager
var editor_settings: EditorSettings:
	get:
		return EditorInterface.get_editor_settings()


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

	mouse_position = raycast_engine.editor_viewport.get_mouse_position()

	var version45: bool = Cursor3DShortcutManager.check_compatibility()

	var set_cursor_path: String = shortcut_manager.shortcut_path + "Set 3D Cursor location"
	var set_new_cursor_path: String = shortcut_manager.shortcut_path + "Create new 3D Cursor"
	var recover_cursor_path: String = shortcut_manager.shortcut_path + "Recover 3D Cursor"
	var show_pie_menu_path: String = shortcut_manager.shortcut_path + "Show Pie Menu"

	var is_set_cursor: bool = version45 and shortcut_manager.registered_shortcuts[set_cursor_path].matches_event(event)
	var is_new_cursor: bool = version45 and shortcut_manager.registered_shortcuts[set_new_cursor_path].matches_event(event)
	var is_recover_cursor: bool = version45 and shortcut_manager.registered_shortcuts[recover_cursor_path].matches_event(event)
	var is_show_pie_menu: bool = version45 and shortcut_manager.registered_shortcuts[show_pie_menu_path].matches_event(event)

	if Cursor3DShortcutManager.check_compatibility():
		_handle_input_for_rest(event)
	elif not Cursor3DShortcutManager.check_compatibility():
		_handle_input_for_v45(event)




func _handle_input_for_rest(event: InputEvent) -> void:
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

	if editor_settings.is_shortcut(shortcut_manager.shortcut_path + "Show Pie Menu", event):
		pie_menu.display()
		return

	if (event is InputEventKey or event is InputEventMouseButton) and pie_menu.visible and not event.is_echo():
		pie_menu.hide()
		# CAUTION: Do not mess with this statement! It can render your editor
		# responseless. If it happens remove the plugin and restart the engine.
		raycast_engine.editor_viewport.set_input_as_handled()


func _handle_input_for_v45(event: InputEvent) -> void:
	if event.is_pressed() and shortcut_manager.registered_shortcuts[shortcut_manager.shortcut_path + "Set 3D Cursor location"].matches_event(event):
			raycast_engine._get_click_location(false, false)
			return
	if event.is_pressed() and shortcut_manager.registered_shortcuts[shortcut_manager.shortcut_path + "Create new 3D Cursor"].matches_event(event):
		raycast_engine._get_click_location(true, false)
		return
	if event.is_pressed() and shortcut_manager.registered_shortcuts[shortcut_manager.shortcut_path + "Recover 3D Cursor"].matches_event(event):
		raycast_engine._get_click_location(false, true)

	if pie_menu.hit_any_button():
		return
	if cursor == null or not cursor.is_inside_tree():
		return

	if shortcut_manager.registered_shortcuts[shortcut_manager.shortcut_path + "Show Pie Menu"].matches_event(event):
		pie_menu.display()
		return

	if (event is InputEventKey or event is InputEventMouseButton) and pie_menu.visible and not event.is_echo():
		pie_menu.hide()
		# CAUTION: Do not mess with this statement! It can render your editor
		# responseless. If it happens remove the plugin and restart the engine.
		raycast_engine.editor_viewport.set_input_as_handled()
