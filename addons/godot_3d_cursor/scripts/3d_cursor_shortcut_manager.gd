class_name Cursor3DShortcutManager
extends Node

enum ShortcutType {
	MOUSE,
	KEY,
}

const shortcut_path: String = "3D Cursor Plugin/"
const available_shortcuts: Array[String] = [
	shortcut_path + "Set 3D Cursor location",
	shortcut_path + "Show Pie Menu",
	shortcut_path + "Create new 3D Cursor",
	shortcut_path + "Recover 3D Cursor"
]
const config_path: String = "res://addons/godot_3d_cursor/.config/shortcuts.cfg"

var plugin_context: Plugin3DCursor

var registered_shortcuts: Dictionary[String, Shortcut] = {}

var editor_settings: EditorSettings:
	get:
		return EditorInterface.get_editor_settings()

var config: ConfigFile

static func check_compatibility() -> bool:
	return Engine.get_version_info().hex >= 0x040600

func setup(plugin_context: Plugin3DCursor) -> void:
	if plugin_context == null:
		push_error("The Cursor3DShortcutManager requires a valid instance of Plugin3DCursor"
			+ " and must not be null."
		)

	self.plugin_context = plugin_context
	config = ConfigFile.new()

	soft_reset_shortcuts()


func create_shortcut(
	type: ShortcutType,
	code: int,
	alt: bool,
	shift: bool,
	ctrl: bool,
	windows: bool,
	auto_remap: bool
	) -> Shortcut:
		var shortcut: Shortcut = Shortcut.new()
		if type == ShortcutType.MOUSE:
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = code
			event.alt_pressed = alt
			event.shift_pressed = shift
			event.ctrl_pressed = ctrl
			event.meta_pressed = windows
			event.command_or_control_autoremap = auto_remap
			shortcut.events = [event]
		elif type == ShortcutType.KEY:
			var event: InputEventKey = InputEventKey.new()
			event.keycode = code
			event.alt_pressed = alt
			event.shift_pressed = shift
			event.ctrl_pressed = ctrl
			event.meta_pressed = windows
			event.command_or_control_autoremap = auto_remap
			shortcut.events = [event]
		else:
			return null
		return shortcut


func apply_shortcuts(shortcuts: Dictionary[String, Shortcut]) -> void:
	for shortcut_path: String in shortcuts.keys():
		if check_compatibility():
			editor_settings.add_shortcut(shortcut_path, shortcuts[shortcut_path])
		registered_shortcuts[shortcut_path] = shortcuts[shortcut_path]
		config.set_value("shortcuts", shortcut_path, shortcuts[shortcut_path])
		plugin_context.signal_hub.shortcut_loaded.emit(shortcuts[shortcut_path], shortcut_path)

	config.save(config_path)


func hard_reset_shortcuts() -> void:
	var shortcuts: Dictionary[String, Shortcut] = get_resetted_shortcuts()
	apply_shortcuts(shortcuts)


func get_resetted_shortcuts() -> Dictionary[String, Shortcut]:
	var shortcuts: Dictionary[String, Shortcut] = {}
	var set_cursor_shortcut: Shortcut = create_shortcut(
		ShortcutType.MOUSE,
		MOUSE_BUTTON_RIGHT,
		false, true, false, false, false
	)
	shortcuts[shortcut_path + "Set 3D Cursor location"] = set_cursor_shortcut

	var show_pie_menu_shortcut: Shortcut = create_shortcut(
		ShortcutType.KEY,
		KEY_S,
		false, true, false, false, false
	)
	shortcuts[shortcut_path + "Show Pie Menu"] = show_pie_menu_shortcut

	var create_cursor_shortcut: Shortcut = create_shortcut(
		ShortcutType.MOUSE,
		MOUSE_BUTTON_RIGHT,
		false, true, true, false, false
	)
	shortcuts[shortcut_path + "Create new 3D Cursor"] = create_cursor_shortcut

	var recover_cursor_shortcut: Shortcut = create_shortcut(
		ShortcutType.MOUSE,
		MOUSE_BUTTON_RIGHT,
		true, true, false, false, false
	)
	shortcuts[shortcut_path + "Recover 3D Cursor"] = recover_cursor_shortcut
	return shortcuts


func soft_reset_shortcuts() -> void:
	var standard_shortcuts: Dictionary[String, Shortcut] = get_resetted_shortcuts()
	var loaded_shortcuts: Dictionary[String, Shortcut] = {}

	if config.load(config_path) != OK:
		apply_shortcuts(standard_shortcuts)
		return

	for shortcut_path: String in available_shortcuts:
		var shortcut: Shortcut = config.get_value("shortcuts", shortcut_path, null)
		if shortcut == null:
			continue
		loaded_shortcuts[shortcut_path] = shortcut
	if loaded_shortcuts.is_empty():
		apply_shortcuts(standard_shortcuts)
		return

	var out: Dictionary[String, Shortcut] = loaded_shortcuts.duplicate(true)
	for shortcut_path: String in standard_shortcuts:
		out.get_or_add(shortcut_path, standard_shortcuts[shortcut_path])

	apply_shortcuts(out)


func remove_all_shortcuts() -> void:
	for shortcut: String in registered_shortcuts:
		editor_settings.remove_shortcut(shortcut)
