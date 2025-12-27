@tool
class_name Plugin3DCursor
extends EditorPlugin
## This class implements a major part of the [i]Godot 3D Cursor[/i] plugin.
##
## It uses the [Cursor3D] class to visually display the [i]3D Cursor[/i] within a scene.
## When installed and enabled, users can place a [i]3D Cursor[/i] by pressing
## [code]Shift + Right Click[/code] on any mesh-based object in the scene.
## Currently, the only officially supported third-party plugin is [Terrain3D]
## by [i]TokisanGames[/i]. For additional third-party support, please refer to the
## [url=https://github.com/Dev-Marco/Godot-3D-Cursor]GitHub repository[/url] and open an issue.

enum NodeNameNumSeparator {
	NONE,
	SPACE,
	UNDERSCORE,
	DASH,
}

## The name of the group that every instance of [Cursor3D] is part of. Helps when dealing with
## duplicates of the cursor.
const CURSOR_GROUP = "Plugin3DCursor"
const CURSOR_COMPONENT_GROUP = "Plugin3DCursorComponent"

## The scene used to instantiate the 3D Cursor
var cursor_scene: PackedScene
## The scene used to instantiate the pie menu for the 3D Cursor
var pie_menu_scene: PackedScene
## The scene of the settings dock for the 3D Cursor
var settings_dock_scene: PackedScene

## The instance of the active 3D Cursor
var cursor: Cursor3D:
	set(value):
		cursor = value
		_last_active_cursors_by_scene[current_scene_path] = value
var _last_active_cursors_by_scene: Dictionary[String, Cursor3D] = {}
var last_active_cursor: Cursor3D:
	get:
		if _last_active_cursors_by_scene.has(current_scene_path) and _last_active_cursors_by_scene.get(current_scene_path) == null:
			return null
		return _last_active_cursors_by_scene.get(current_scene_path)
## The instance of the pie menu for the 3D Cursor
var pie_menu: PieMenu
## The instance of the settings dock for the 3D Cursor
var settings_dock: SettingsDock

var signal_hub: Cursor3DSignalHub
var undo_redo_manager: Cursor3DUndoRedoManager
var cursor_actions: Cursor3DActions
var command_palette_manager: Cursor3DCommandPaletteManager
var input_manager: Cursor3DInputManager
var raycast_engine: Cursor3DRaycastEngine

## This variable holds the name of the currently active tab. It is useful to
## prevent triggering certain Inputs outside of the 3D tab.
var _main_screen: String = ""
var cursor_counter: Dictionary[String, int] = {}
var current_scene_path: String:
	get:
		return EditorInterface.get_edited_scene_root().scene_file_path


func _enter_tree() -> void:
	signal_hub = Cursor3DSignalHub.new()
	add_child(signal_hub)
	signal_hub.clear_cursor_pressed.connect(unset_cursor)
	signal_hub.cursor_recovered.connect(set_cursor)
	undo_redo_manager = Cursor3DUndoRedoManager.new(self)
	add_child(undo_redo_manager)
	cursor_actions = Cursor3DActions.new(self, undo_redo_manager)
	add_child(cursor_actions)
	command_palette_manager = Cursor3DCommandPaletteManager.new(self)
	add_child(command_palette_manager)
	input_manager = Cursor3DInputManager.new(self)
	add_child(input_manager)
	raycast_engine = Cursor3DRaycastEngine.new(self)
	add_child(raycast_engine)
	_provide_3d_cursor_warnings()
	_setup_editor_events()
	_preload_3d_cursor_ui_components()
	_setup_pie_menu()
	_setup_settings_dock()


func _exit_tree() -> void:
	_disconnect_editor_events()
	_free_3d_cursor()
	_free_all_3d_cursors()
	_free_pie_menu()
	_free_settings_dock()
	signal_hub.queue_free()
	undo_redo_manager.queue_free()
	cursor_actions.queue_free()
	command_palette_manager.queue_free()
	input_manager.queue_free()
	raycast_engine.queue_free()


### --------------------------  Setup Functions  --------------------------- ###

## This function sets up all warnings connected to the 3D Cursor.
func _provide_3d_cursor_warnings():
	if not Cursor3DRaycastEngine.check_compatibility():
		push_warning(
			"Godot 3D Cursor 1.4.0 requires features introduced in Godot 4.5. "
		 	+ "The plugin has reverted to legacy physics-based raycasting due to "
			+ "missing engine functionality.\n\n"
			+ "Upgrade to Godot 4.5 or newer to enable the full feature set."
		)


## This function sets up all events necessary for the 3D Cursor to work correctly.
func _setup_editor_events():
	# Register the switching of tabs in the editor. We only want the
	# 3D Cursor functionality within the 3D tab
	main_screen_changed.connect(_on_main_screen_changed)
	scene_changed.connect(_on_scene_changed)
	# We want to place newly added Nodes that inherit [Node3D] at
	# the location of the 3D Cursor. Therefore we listen to the
	# node_added event
	get_tree().node_added.connect(_on_node_added)


## This function preloads every scene for the 3D Cursor.
func _preload_3d_cursor_ui_components():
	# Loading the 3D Cursor scene for later instancing
	cursor_scene = preload("uid://dfpatff4d5okj")
	pie_menu_scene = preload("uid://igrlue2n5478")
	settings_dock_scene = preload("uid://dt0ngqiwc0150")


## This function sets up the pie menu for the 3D Cursor.
func _setup_pie_menu():
	# Instantiating the pie menu for the 3D Cursor commands
	pie_menu = pie_menu_scene.instantiate()
	pie_menu.hide()
	add_child(pie_menu)
	pie_menu.setup(self)


## This function sets up the settings dock for the 3D Cursor.
func _setup_settings_dock():
	# Instantiating the settings dock
	settings_dock = settings_dock_scene.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, settings_dock)
	settings_dock.setup(self)


### --------------------------  Remove Functions  -------------------------- ###

## This method disconnects the editor events.
func _disconnect_editor_events():
	# Removing listeners
	main_screen_changed.disconnect(_on_main_screen_changed)
	scene_changed.disconnect(_on_scene_changed)
	get_tree().node_added.disconnect(_on_node_added)


## This method will free the cursor and remove the reference to the [Cursor3D] scene.
func _free_3d_cursor():
	# Deleting the 3D Cursor
	free_cursor()
	cursor_scene = null


func _free_all_3d_cursors():
	for cursor: Cursor3D in get_all_cursors():
		cursor.queue_free()


## This method will free the pie menu and remove the reference to the [PieMenu] scene.
func _free_pie_menu():
	# Deleting the pie menu
	if pie_menu != null:
		pie_menu.queue_free()
	pie_menu_scene = null


## This method will free the settings dock and remove the reference to the [SettingsDock] scene.
func _free_settings_dock():
	# Deleting the settings dock
	if settings_dock != null:
		remove_control_from_docks(settings_dock)
		settings_dock.queue_free()
	settings_dock_scene = null


### --------------------------  Editor Bindings  --------------------------- ###

## Checks whether the current active tab is named '3D'
## returns true if so, otherwise false
func _on_main_screen_changed(screen_name: String) -> void:
	_main_screen = screen_name


func _on_scene_changed(scene_root: Node) -> void:
	signal_hub.cursor_recovered.emit(last_active_cursor)
	cursor_counter[current_scene_path] = get_all_cursors().size()


## Connected to the node_added event of the get_tree()
func _on_node_added(node: Node) -> void:
	if not cursor_available():
		return
	if EditorInterface.get_edited_scene_root() != cursor.owner:
		return
	if node.name == cursor.name:
		return
	if cursor.is_ancestor_of(node):
		return
	if not node is Node3D:
		return
	if node.is_in_group(CURSOR_COMPONENT_GROUP):
		return
	# Apply the position of the new node to the 3D Cursors position if the
	# 3D cursor is available, the node is not the 3D cursor itself, the node
	# is no descendant of the 3D Cursor and the node inherits [Node3D]
	node.global_position = cursor.global_position


### -------------------------  3D Cursor Actions  -------------------------- ###

## Sets the correct label on the toggle visibility button in the pie menu
func _set_visibility_toggle_label() -> void:
	pie_menu.change_toggle_label(cursor.visible)


## A wrapper for [member Plugin3DCursor.available_cursor] for an easy boolean
## check to see if an instance of [Cursor3D] is set up in the current scene.
func cursor_available(ignore_hidden = false) -> bool:
	return available_cursor(ignore_hidden) != null


## Check whether the 3D Cursor is set up and ready for use. A hidden 3D Cursor
## should also disable its functionality. Therefore this function yields [code]null[/code]
## if the cursor is hidden in the scene unless [param ignore_hidden] is set to
## [code]true[/code], then it yields the available [Cursor3D] instance.
func available_cursor(ignore_hidden: bool = false) -> Cursor3D:
	# CAUTION: Do not mess with this statement! It can render your editor
	# responseless. If it happens remove the plugin and restart the engine.
	raycast_engine.editor_viewport.set_input_as_handled()
	if cursor == null:
		return null
	if not cursor.is_inside_tree():
		return null
	if ignore_hidden and not cursor.is_visible_in_tree():
		return cursor
	if not cursor.is_visible_in_tree():
		return null
	return cursor


### ------------------------------  Utility  ------------------------------- ###

## Returns all instances of a [Cursor3D] instance within a scene in an [code]Array[Cursor3D][/code]
func get_all_cursors() -> Array[Cursor3D]:
	var out: Array[Cursor3D] = []
	out.assign(get_tree().get_nodes_in_group(CURSOR_GROUP))
	out.sort_custom(func(a: Node, b: Node): return a.name.naturalnocasecmp_to(b.name) < 0)
	return out


func get_newest_cursor() -> Cursor3D:
	var cursors: Array[Cursor3D] = get_all_cursors()
	if cursors.is_empty():
		return null
	return cursors.back()


## Checks whether the active tab is 3D or not. If the user did not switch any tab since startup
## or since enabling the plugin we fall back to a hacky solution trying find the active tab.
func is_in_3d_tab() -> bool:
	# When the _main_screen variable is empty, this means the user has not switched tabs
	# If it is not, we return whether it is "3D"
	if not _main_screen.is_empty():
		return _main_screen == "3D"

	# WARNING: Hacky solution below
	var editor_main_screen := EditorInterface.get_editor_main_screen()
	var screen := editor_main_screen.get_children()[1]
	if not screen is Node:
		return false

	return screen.is_visible_in_tree()


func unset_cursor() -> void:
	if cursor == null:
		return
	_last_active_cursors_by_scene.erase(current_scene_path)
	cursor = null


func set_cursor(cursor: Cursor3D) -> void:
	self.cursor = cursor


func free_cursor() -> void:
	if cursor == null:
		return
	cursor.queue_free()
	cursor = null


func create_cursor() -> void:
	cursor = cursor_scene.instantiate()
	cursor.setup(self, cursor_counter.get_or_add(current_scene_path, 0))
	raycast_engine.edited_scene_root.add_child(cursor)
	cursor.owner = raycast_engine.true_edited_scene_root
	if cursor_counter.get(current_scene_path) > 0:
		var separator: String = ""
		match ProjectSettings.get_setting("editor/naming/node_name_num_separator"):
			NodeNameNumSeparator.NONE:
				pass
			NodeNameNumSeparator.SPACE:
				separator = " "
			NodeNameNumSeparator.UNDERSCORE:
				separator = "_"
			NodeNameNumSeparator.DASH:
				separator = "-"

		cursor.name = "3DCursor{separator}{counter}".format({
			"separator": separator,
			"counter": cursor_counter.get(current_scene_path),
		})
	cursor_counter[current_scene_path] += 1
	signal_hub.cursor_created.emit(cursor)


func add_cursor_to_tree() -> void:
	if cursor == null:
		return
	raycast_engine.edited_scene_root.add_child(cursor)
	cursor.owner = raycast_engine.edited_scene_root
	signal_hub.cursor_created.emit(cursor)
