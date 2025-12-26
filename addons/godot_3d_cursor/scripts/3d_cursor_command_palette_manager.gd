class_name Cursor3DCommandPaletteManager
extends Node

var plugin_context: Plugin3DCursor

var _command_palette: EditorCommandPalette


func _init(plugin_context: Plugin3DCursor) -> void:
	if plugin_context == null:
		push_error("The Cursor3DCommandPaletteManager requires a valid instance of Plugin3DCursor"
			+ " and must not be null."
		)
	self.plugin_context = plugin_context

	_command_palette = EditorInterface.get_command_palette()
	# Adding the previously mentioned actions
	_command_palette.add_command(
		"3D Cursor to Origin", "3D Cursor/3D Cursor to Origin",
		func(): plugin_context.signal_hub.cursor_to_origin.emit()
	)
	_command_palette.add_command(
		"3D Cursor to Selected Object", "3D Cursor/3D Cursor to Selected Object",
		func(): plugin_context.signal_hub.cursor_to_selected_objects.emit()
	)
	_command_palette.add_command(
		"Selected Object to 3D Cursor", "3D Cursor/Selected Object to 3D Cursor",
		func(): plugin_context.signal_hub.selected_object_to_cursor.emit()
	)
	# Adding the remove 3D Cursor in Scene action
	_command_palette.add_command(
		"Remove Active 3D Cursor from Scene", "3D Cursor/Remove Active 3D Cursor from Scene",
		func(): plugin_context.signal_hub.remove_active_cursor_from_scene.emit()
	)
	_command_palette.add_command(
		"Remove All 3D Cursors from Scene", "3D Cursor/Remove All 3D Cursors from Scene",
		func(): plugin_context.signal_hub.remove_all_cursors_from_scene.emit()
	)
	_command_palette.add_command(
		"Toggle 3D Cursor", "3D Cursor/Toggle 3D Cursor",
		func(): plugin_context.signal_hub.toggle_cursor.emit()
	)
	_command_palette.add_command(
		"Move Active 3D Cursor to ...", "3D Cursor/Move Active 3D Cursor to",
		func(): plugin_context.settings_dock.select_node_for_move_to()
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_cleanup()


func _cleanup():
	# Removing the actions from the [EditorCommandPalette]
	_command_palette.remove_command("3D Cursor/3D Cursor to Origin")
	_command_palette.remove_command("3D Cursor/3D Cursor to Selected Object")
	_command_palette.remove_command("3D Cursor/Selected Object to 3D Cursor")
	_command_palette.remove_command("3D Cursor/Remove Active 3D Cursor from Scene")
	_command_palette.remove_command("3D Cursor/Remove All 3D Cursors from Scene")
	_command_palette.remove_command("3D Cursor/Toggle 3D Cursor")
	_command_palette.remove_command("3D Cursor/Move Active 3D Cursor to")
