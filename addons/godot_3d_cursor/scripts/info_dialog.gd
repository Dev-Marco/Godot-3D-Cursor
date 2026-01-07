@tool
class_name InfoDialog
extends Window

@onready var version: RichTextLabel = $MarginContainer/VBoxContainer/Version


func _on_close_requested() -> void:
	hide()


func _open_link_in_browser(meta: Variant) -> void:
	if not meta is String:
		return
	OS.shell_open(meta)


func _on_visibility_changed() -> void:
	if not visible:
		return
	var parent: SettingsDock = get_parent()
	if parent == null:
		return
	if parent.plugin_context == null:
		return
	version.text = "Version {version}".format({
		"version": parent.plugin_context.get_plugin_version()
	})
