@tool
class_name SettingsDock
extends Control

## Emitted whenever a cursor is being deleted.
signal cursor_deleted(name: String)
## Emitted when a cursor is created or recovered.
signal cursor_created(cursor: Cursor3D)

var plugin_context: Plugin3DCursor

@onready var button: Button = $MarginContainer/VBoxContainer/Button


func init_signals() -> void:
	if plugin_context == null:
		return
	plugin_context.cursor_created.connect(_on_cursor_created)
	plugin_context.cursor_deleted.connect(_on_cursor_deleted)


func _on_button_pressed() -> void:
	pass


func _on_cursor_created(cursor: Cursor3D) -> void:
	cursor_created.emit(cursor)


func _on_cursor_deleted(name: String) -> void:
	cursor_deleted.emit(name)


func _on_line_edit_cursor_selected(cursor: Cursor3D) -> void:
	if plugin_context == null:
		return
	plugin_context.set_cursor(cursor)


func _on_line_edit_cursor_deselected() -> void:
	if plugin_context == null:
		return
	plugin_context.unset_cursor()
