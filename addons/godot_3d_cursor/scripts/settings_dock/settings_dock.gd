@tool
class_name SettingsDock
## This class implements an editor dock that bundles settings and functionality for
## the Godot 3D Cursor Plugin ([Plugin3DCursor]).
##
## The settings dock provides a centralized place to manage all configuration options
## related to the Godot 3D Cursor. Settings that were previously configured directly on
## [Cursor3D] instances are now accessible through this dock.[br][br]
##
## The dock allows users to configure the raycast mode and, if the Terrain3D plugin is
## used, to make all Terrain3D nodes compatible by assigning the required group to each
## instance. It also enables working with multiple [Cursor3D] instances per scene and
## managing them via simple drag-and-drop interactions.[br][br]
##
## In addition, all actions previously available through the [PieMenu] or the command
## palette ([code]CTRL + SHIFT + P[/code]) can also be accessed via the action buttons
## in the “Actions” section of the settings dock.[br][br]
## Useful shortcuts are:[br]
## - [code]SHIFT + Left Click[/code] to place a cursor.
## - [code]SHIFT + CTRL + Left Click[/code] to place a new cursor while having an active one
## - [code]SHIFT + ALT + Left Click[/code] to recover the youngest cursor within the scene
## and move it to the desired position.
extends Control

## The reference to the plugin core.
var plugin_context: Plugin3DCursor
## The reference to the instance that holds all relevant signals.
var signal_hub: Cursor3DSignalHub:
	get:
		return plugin_context.signal_hub
var shortcut_manager: Cursor3DShortcutManager:
	get:
		return plugin_context.shortcut_manager

var default_normal_color: Color = Color.hex(0xd9b500ff)
var default_active_color: Color = Color.hex(0xff8c00ff)
var default_selected_color: Color = Color.hex(0x00f2ffff)
var cursor_normal_color: Color:
	get:
		if normal_color_picker_button == null:
			return default_normal_color
		return normal_color_picker_button.color
var cursor_active_color: Color:
	get:
		if active_color_picker_button == null:
			return default_active_color
		return active_color_picker_button.color
var cursor_selected_color: Color:
	get:
		if selected_color_picker_button == null:
			return default_selected_color
		return selected_color_picker_button.color
var set_3d_cursor_location_shortcut: String = ""

## The container that holds the buttons that add/remove the 'Terrain3D' group
## from [Terrain3D] instances.
@onready var add_remove_terrain_3d_group: HBoxContainer = %AddRemoveTerrain3DGroup
## The LineEdit that displays the name of the active cursor. The user can drop
## [Cursor3D] instances on it to set a new active cursor.
@onready var active_cursor_line_edit: ActiveCursorLineEdit = %ActiveCursorLineEdit
## The button to deselect the [Cursor3D] instance in the world.
@onready var deselect_cursor_button: Button = %DeselectCursorButton
## The button on that invokes the action to move the cursor to a target position.
@onready var move_active_cursor_button: MoveActiveCursorButton = %MoveActiveCursorButton
## A reference to the object holding the targets position for the
## [member SettingsDock.move_active_cursor_button].
@onready var move_action_coordinates: MoveActionCoordinates = %MoveActionCoordinates
## The button that hides/shows the active [Cursor3D].
@onready var toggle_cursor_button: Button = %ToggleCursorButton
## The spinner for the scale setting of the [Cursor3D].
@onready var scale_spin_box: SpinBox = %ScaleSpinBox
## The setting that toggles whether the labels of the active [Cursor3D] scale
## with it.
@onready var scale_affect_labels_check_box: CheckBox = %ScaleAffectLabelsCheckBox
## The setting that toggles whether the title label is shown.
@onready var show_title_label_check_box: CheckBox = %ShowTitleLabelCheckBox
## The setting that toggles whether the number label is shown.
@onready var show_number_label_check_box: CheckBox = %ShowNumberLabelCheckBox
## The dropdown menu that allows the user to select the raycast mode.
@onready var raycast_mode_option_button: OptionButton = %RaycastModeOptionButton
## The Setting that toggles whether the newest [Cursor3D] is automatically recovered
## if no active cursor is set. The same action as if the user uses
## [code]Shift + Ctrl + Right Click[/code].
@onready var auto_recover_check_box: CheckBox = %AutoRecoverCheckBox
## The container that holds all action buttons from the settings dock.
@onready var action_buttons: GridContainer = %ActionButtons
## The button that removes all intances of [Cursor3D] from the current scene.
@onready var remove_all_cursors_from_scene_button: Button = %RemoveAllCursorsFromSceneButton
@onready var remove_active_cursor_from_scene_button: Button = %RemoveActiveCursorFromSceneButton
@onready var grid_spacer: Control = %GridSpacer
@onready var normal_color_picker_button: ColorPickerButton = %NormalColorPickerButton
@onready var active_color_picker_button: ColorPickerButton = %ActiveColorPickerButton
@onready var selected_color_picker_button: ColorPickerButton = %SelectedColorPickerButton
@onready var set_3d_cursor_location_line_edit: LineEdit = %Set3DCursorLocationLineEdit
@onready var show_pie_menu_line_edit: LineEdit = %ShowPieMenuLineEdit
@onready var create_new_3d_cursor_line_edit: LineEdit = %CreateNew3DCursorLineEdit
@onready var recover_3d_cursor_line_edit: LineEdit = %Recover3DCursorLineEdit

@onready var shortcuts: VBoxContainer = %Shortcuts
@onready var shortcut_section_toggle_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Heading/ShortcutSectionToggleButton
@onready var alt_modifier_1: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Set3DCursorLocation/Modifiers/AltModifier
@onready var shift_modifier_1: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Set3DCursorLocation/Modifiers/ShiftModifier
@onready var ctrl_modifier_1: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Set3DCursorLocation/Modifiers/CtrlModifier
@onready var windows_modifier_1: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Set3DCursorLocation/Modifiers/WindowsModifier
@onready var auto_remap_control_modifier_1: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Set3DCursorLocation/Modifiers/AutoRemapControlModifier
@onready var alt_modifier_2: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/ShowPieMenu/Modifiers/AltModifier
@onready var shift_modifier_2: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/ShowPieMenu/Modifiers/ShiftModifier
@onready var ctrl_modifier_2: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/ShowPieMenu/Modifiers/CtrlModifier
@onready var windows_modifier_2: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/ShowPieMenu/Modifiers/WindowsModifier
@onready var auto_remap_control_modifier_2: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/ShowPieMenu/Modifiers/AutoRemapControlModifier
@onready var alt_modifier_3: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/CreateNew3DCursor/Modifiers/AltModifier
@onready var shift_modifier_3: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/CreateNew3DCursor/Modifiers/ShiftModifier
@onready var ctrl_modifier_3: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/CreateNew3DCursor/Modifiers/CtrlModifier
@onready var windows_modifier_3: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/CreateNew3DCursor/Modifiers/WindowsModifier
@onready var auto_remap_control_modifier_3: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/CreateNew3DCursor/Modifiers/AutoRemapControlModifier
@onready var alt_modifier_4: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Recover3DCursor/Modifiers/AltModifier
@onready var shift_modifier_4: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Recover3DCursor/Modifiers/ShiftModifier
@onready var ctrl_modifier_4: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Recover3DCursor/Modifiers/CtrlModifier
@onready var windows_modifier_4: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Recover3DCursor/Modifiers/WindowsModifier
@onready var auto_remap_control_modifier_4: CheckBox = $ScrollContainer/MarginContainer/VBoxContainer/ShortcutsSection/Shortcuts/Recover3DCursor/Modifiers/AutoRemapControlModifier

@onready var _optional_modifiers = {
	"set_location": [ctrl_modifier_1, windows_modifier_1],
	"show_pie_menu": [ctrl_modifier_2, windows_modifier_2],
	"create_new": [ctrl_modifier_3, windows_modifier_3],
	"recover_cursor": [ctrl_modifier_4, windows_modifier_4],
}
@onready var set_3d_cursor_location_modifiers = {
	"alt": alt_modifier_1,
	"shift": shift_modifier_1,
	"ctrl": ctrl_modifier_1,
	"windows": windows_modifier_1,
	"auto_remap": auto_remap_control_modifier_1
}
@onready var show_pie_menu_modifiers = {
	"alt": alt_modifier_2,
	"shift": shift_modifier_2,
	"ctrl": ctrl_modifier_2,
	"windows": windows_modifier_2,
	"auto_remap": auto_remap_control_modifier_2
}
@onready var create_new_3d_cursor_modifiers = {
	"alt": alt_modifier_3,
	"shift": shift_modifier_3,
	"ctrl": ctrl_modifier_3,
	"windows": windows_modifier_3,
	"auto_remap": auto_remap_control_modifier_3
}
@onready var recover_3d_cursor_modifiers = {
	"alt": alt_modifier_4,
	"shift": shift_modifier_4,
	"ctrl": ctrl_modifier_4,
	"windows": windows_modifier_4,
	"auto_remap": auto_remap_control_modifier_4
}


## Sets up the [member SettingsDock.plugin_context] and connects to multiple
## signals from the [member SettingsDock.signal_hub].
func setup(plugin_context: Plugin3DCursor) -> void:
	# A plugin context is required, therefore it must not be null.
	if plugin_context == null:
		push_error("The settings dock requires a valid instance of Plugin3DCursor"
			+ "and must not be null."
		)
		return
	self.plugin_context = plugin_context
	# Pass through the plugin_context to the children that need it.
	active_cursor_line_edit.setup(plugin_context)
	move_active_cursor_button.setup(plugin_context)

	# Connect the signals that are required.
	signal_hub.active_cursor_line_edit_clicked.connect(_active_cursor_line_edit_clicked)
	signal_hub.active_cursor_line_edit_data_dropped.connect(_assign_active_cursor)
	signal_hub.deselect_cursor_pressed.connect(_on_deselect_cursor_button_pressed)
	signal_hub.cursor_created.connect(_on_cursor_created)
	signal_hub.active_cursor_deleted.connect(_on_active_cursor_deleted)
	signal_hub.remove_all_cursors_from_scene.connect(_on_all_cursors_removed_from_scene)
	signal_hub.cursor_recovered.connect(_on_cursor_recovered)
	signal_hub.shortcut_loaded.connect(_on_shortcut_loaded)

	# If the current version of Godot is not compatible, disable the
	# 'Physicsless' raycast mode and select 'Physics' instead.
	if not Cursor3DRaycastEngine.check_compatibility():
		raycast_mode_option_button.set_item_disabled(1, true)
		raycast_mode_option_button.select(3)
		raycast_mode_option_button.item_selected.emit(3)


## Assigns a [Cursor3D] via a [NodePath] and displays it.
func _assign_active_cursor(node_path: NodePath):
	if node_path == null or node_path.is_empty():
		return
	# Get the node from the NodePath
	var cursor: Cursor3D = EditorInterface.get_edited_scene_root().get_node_or_null(node_path)
	if cursor == null:
		return
	# We set the LineEdit's text to the name of the Cursor3D from data
	active_cursor_line_edit.text = cursor.name
	# We save the reference to the Cursor3D instance itself
	plugin_context.set_cursor(cursor)
	get_settings_from_active_cursor()
	set_toggle_cursor_button_label()
	toggle_action_buttons(true)
	toggle_action_buttons_for_disabled_cursor()


## Toggles the label of the [member SettingsDock.toggle_cursor_button] to be
## visibility state aware.
func set_toggle_cursor_button_label() -> void:
	if plugin_context.cursor == null or plugin_context.cursor.visible:
		toggle_cursor_button.text = "Disable 3D Cursor"
	else:
		toggle_cursor_button.text = "Enable 3D Cursor"


## Disables/Enables all buttons except
## [member SettingsDock.remove_all_cursors_from_scene_button] depending on
## [param toggle_on].
func toggle_action_buttons(toggle_on: bool = false) -> void:
	# Go through all children of the actions grid
	for child in action_buttons.get_children():
		# Every button except the remove all cursors from scene button
		if not child is Button or child == remove_all_cursors_from_scene_button:
			continue
		child.disabled = not toggle_on


func toggle_action_buttons_for_disabled_cursor() -> void:
	if plugin_context.cursor == null:
		return
	for child in action_buttons.get_children():
		if not child is Button \
			or child == remove_all_cursors_from_scene_button \
			or child == remove_active_cursor_from_scene_button \
			or child == toggle_cursor_button:
				continue
		child.disabled = not plugin_context.cursor.visible


func _on_cursor_created(cursor: Cursor3D) -> void:
	active_cursor_line_edit.text = cursor.name
	set_toggle_cursor_button_label()
	get_settings_from_active_cursor()
	toggle_action_buttons(true)
	toggle_action_buttons_for_disabled_cursor()


func _on_active_cursor_deleted() -> void:
	active_cursor_line_edit.clear()
	set_toggle_cursor_button_label()
	reset_cursor_settings()
	toggle_action_buttons()


func _on_all_cursors_removed_from_scene() -> void:
	_on_active_cursor_deleted()


func _on_cursor_recovered(cursor: Cursor3D) -> void:
	if cursor == null:
		active_cursor_line_edit.clear()
		toggle_action_buttons()
		return
	_on_cursor_created(cursor)


func _on_clear_button_pressed() -> void:
	active_cursor_line_edit.clear()
	signal_hub.clear_cursor_pressed.emit()
	set_toggle_cursor_button_label()
	reset_cursor_settings()
	toggle_action_buttons()


func _on_deselect_cursor_button_pressed() -> void:
	if plugin_context.cursor == null:
		return
	var editor_selection = EditorInterface.get_selection()
	if not plugin_context.cursor in editor_selection.get_selected_nodes():
		return
	editor_selection.remove_node(plugin_context.cursor)


func _on_line_edit_cursor_selected(cursor: Cursor3D) -> void:
	if plugin_context == null:
		return
	plugin_context.set_cursor(cursor)


func _active_cursor_line_edit_clicked(double_click: bool = false) -> void:
	if Input.is_key_pressed(KEY_ALT) or active_cursor_line_edit.text.is_empty():
		EditorInterface.popup_node_selector(_assign_active_cursor, ["Cursor3D"])
		signal_hub.active_cursor_line_edit_cursor_selected.emit(plugin_context.cursor)
		return
	if plugin_context.cursor == null:
		return
	var editor_selection: EditorSelection = EditorInterface.get_selection()
	editor_selection.clear()
	editor_selection.add_node(plugin_context.cursor)
	if double_click:
		_focus_selection_in_editor()
		return
	if Input.is_key_pressed(KEY_CTRL):
		_focus_selection_in_editor(true)


func _focus_selection_in_editor(zoom_to: bool = false) -> void:
	var editor_camera: Camera3D = plugin_context.raycast_engine.editor_camera
	if editor_camera == null or plugin_context.cursor == null:
		return

	editor_camera.look_at(plugin_context.cursor.global_position)

	if zoom_to:
		var distance: float = 30.0
		var dir: Vector3 = (plugin_context.cursor.global_position - editor_camera.global_position).normalized()
		var dist_to = plugin_context.cursor.global_position.distance_to(editor_camera.global_position)
		var target_position: Vector3 = editor_camera.global_position + (dist_to - distance) * dir
		var tween: Tween = editor_camera.create_tween()
		var tween_duration: float = 0.25
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(editor_camera, "global_position", target_position, tween_duration)


func reset_cursor_settings() -> void:
	scale_spin_box.set_value_no_signal(1.0)
	scale_affect_labels_check_box.set_pressed_no_signal(true)
	show_title_label_check_box.set_pressed_no_signal(true)
	show_number_label_check_box.set_pressed_no_signal(true)


func get_settings_from_active_cursor() -> void:
	var cursor: Cursor3D = plugin_context.cursor
	if cursor == null:
		return
	scale_spin_box.set_value_no_signal(cursor.size_scale)
	scale_affect_labels_check_box.set_pressed_no_signal(cursor.scale_affect_labels)
	show_title_label_check_box.set_pressed_no_signal(cursor.show_title_label)
	show_number_label_check_box.set_pressed_no_signal(cursor.show_number_label)


func get_node_selector_dialog() -> Window:
	var controls: Array = EditorInterface.get_base_control().find_children(
		"*", "SceneTreeDialog", true, false
	)
	return null if controls.is_empty() else controls.back()


func set_node_selector_title(title: String) -> void:
	var node_selector: Window = get_node_selector_dialog()
	if node_selector == null:
		return
	node_selector.title = title


func reset_node_selector_title() -> void:
	set_node_selector_title("Select a Node")


func _toggle_shortcut_modifiers_for(toggled_on: bool, shortcut: String) -> void:
	for modifier: CheckBox in _optional_modifiers[shortcut]:
		modifier.disabled = toggled_on
		modifier.visible = not toggled_on


func _on_use_terrain_3d_check_box_toggled(toggled_on: bool) -> void:
	add_remove_terrain_3d_group.visible = toggled_on


func _on_add_terrain_3d_group_button_pressed() -> void:
	var terrain3ds: Array[Node] = EditorInterface.get_edited_scene_root().find_children(
		"*", "Terrain3D", true, false
	)
	for terrain3d: Node in terrain3ds:
		if terrain3d.is_in_group("Terrain3D"):
			continue
		terrain3d.add_to_group("Terrain3D")


func _on_remove_terrain_3d_group_button_pressed() -> void:
	EditorInterface.get_edited_scene_root().get_tree().get_nodes_in_group("Terrain3D").map(
		func(node: Node): node.remove_from_group("Terrain3D")
	)


func _on_cursor_to_origin_button_pressed() -> void:
	signal_hub.cursor_to_origin.emit()


func _on_selected_object_to_cursor_button_pressed() -> void:
	signal_hub.selected_object_to_cursor.emit()


func _on_cursor_to_selected_objects_button_pressed() -> void:
	signal_hub.cursor_to_selected_objects.emit()


func _on_toggle_cursor_button_pressed() -> void:
	signal_hub.toggle_cursor.emit()


func _on_remove_active_cursor_from_scene_button_pressed() -> void:
	signal_hub.remove_active_cursor_from_scene.emit()


func _on_move_active_cursor_button_pressed() -> void:
	select_node_for_move_to()


func select_node_for_move_to() -> void:
	if plugin_context.cursor == null:
		return
	EditorInterface.popup_node_selector(_on_node_for_move_to_selected, ["Node3D"])


func _on_node_for_move_to_selected(node_path: NodePath) -> void:
	if node_path.is_empty():
		return
	var target: Node3D = EditorInterface.get_edited_scene_root().get_node_or_null(node_path)
	if target == null:
		return
	if target == plugin_context.cursor:
		return
	signal_hub.move_active_cursor_to.emit(target.global_position)


func _on_remove_all_cursors_from_scene_button_pressed() -> void:
	signal_hub.remove_all_cursors_from_scene.emit()


func _on_create_path_3d_from_cursors_button_pressed() -> void:
	if plugin_context.get_all_cursors().is_empty():
		return
	EditorInterface.popup_node_selector(_create_path_3d_from_cursors, ["Node3D"])
	set_node_selector_title("Select a parent for the new Path3D")


func _create_path_3d_from_cursors(node_path: NodePath) -> void:
	reset_node_selector_title()
	if node_path == null or node_path.is_empty():
		return
	# Get the node from the NodePath
	var selected_root: Node3D = EditorInterface.get_edited_scene_root().get_node_or_null(node_path)
	if selected_root == null:
		return
	var path_3d: Path3D = Path3D.new()
	selected_root.add_child(path_3d)
	path_3d.owner = EditorInterface.get_edited_scene_root()
	path_3d.curve = Curve3D.new()
	for cursor: Cursor3D in plugin_context.get_all_cursors():
		path_3d.curve.add_point(path_3d.to_local(cursor.global_position))


func _on_scale_spin_box_value_changed(value: float) -> void:
	if plugin_context.cursor == null:
		return
	plugin_context.cursor.size_scale = value


func _on_scale_affect_labels_check_box_toggled(toggled_on: bool) -> void:
	if plugin_context.cursor == null:
		return
	plugin_context.cursor.scale_affect_labels = toggled_on


func _on_show_title_label_check_box_toggled(toggled_on: bool) -> void:
	if plugin_context.cursor == null:
		return
	plugin_context.cursor.show_title_label = toggled_on


func _on_show_number_label_check_box_toggled(toggled_on: bool) -> void:
	if plugin_context.cursor == null:
		return
	plugin_context.cursor.show_number_label = toggled_on


func _on_raycast_mode_option_button_item_selected(index: int) -> void:
	match index:
		1:
			signal_hub.raycast_mode_changed.emit(Cursor3DRaycastEngine.RaycastMode.PHYSICSLESS)
		3:
			signal_hub.raycast_mode_changed.emit(Cursor3DRaycastEngine.RaycastMode.PHYSICS)
		_:
			pass


func _on_info_button_pressed() -> void:
	$InfoDialog.show()


func _on_move_action_coordinates_visibility_changed() -> void:
	grid_spacer.visible = move_action_coordinates.visible


func _on_normal_color_picker_button_color_changed(color: Color) -> void:
	plugin_context.signal_hub.cursor_normal_color_changed.emit(color)


func _on_active_color_picker_button_color_changed(color: Color) -> void:
	plugin_context.signal_hub.cursor_active_color_changed.emit(color)


func _on_selected_color_picker_button_color_changed(color: Color) -> void:
	plugin_context.signal_hub.cursor_selected_color_changed.emit(color)


func _on_reset_normal_color_button_pressed() -> void:
	normal_color_picker_button.color = default_normal_color
	normal_color_picker_button.color_changed.emit(default_normal_color)


func _on_reset_active_color_button_pressed() -> void:
	active_color_picker_button.color = default_active_color
	active_color_picker_button.color_changed.emit(default_active_color)


func _on_reset_selected_color_button_pressed() -> void:
	selected_color_picker_button.color = default_selected_color
	selected_color_picker_button.color_changed.emit(default_selected_color)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton or event is InputEventKey):
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).double_click:
		return
	if event.is_released():
		return
	if set_3d_cursor_location_line_edit.has_focus():
		_parse_event(event, set_3d_cursor_location_line_edit, set_3d_cursor_location_modifiers)
	elif show_pie_menu_line_edit.has_focus():
		_parse_event(event, show_pie_menu_line_edit, show_pie_menu_modifiers)
	elif create_new_3d_cursor_line_edit.has_focus():
		_parse_event(event, create_new_3d_cursor_line_edit, create_new_3d_cursor_modifiers)
	elif recover_3d_cursor_line_edit.has_focus():
		_parse_event(event, recover_3d_cursor_line_edit, recover_3d_cursor_modifiers)


func _on_set_3d_cursor_location_line_edit_mouse_exited() -> void:
	set_3d_cursor_location_line_edit.release_focus()

func _on_set_3d_cursor_location_line_edit_mouse_entered() -> void:
	set_3d_cursor_location_line_edit.grab_focus()


func _on_show_pie_menu_line_edit_mouse_exited() -> void:
	show_pie_menu_line_edit.release_focus()

func _on_show_pie_menu_line_edit_mouse_entered() -> void:
	show_pie_menu_line_edit.grab_focus()

func _on_create_new_3d_cursor_line_edit_mouse_exited() -> void:
	create_new_3d_cursor_line_edit.release_focus()

func _on_create_new_3d_cursor_line_edit_mouse_entered() -> void:
	create_new_3d_cursor_line_edit.grab_focus()


func _on_recover_3d_cursor_line_edit_mouse_exited() -> void:
	recover_3d_cursor_line_edit.release_focus()

func _on_recover_3d_cursor_line_edit_mouse_entered() -> void:
	recover_3d_cursor_line_edit.grab_focus()


func _on_shortcut_loaded(shortcut: Shortcut, path: String) -> void:
	var line_edit: LineEdit = null
	var modifiers: Dictionary = {}
	if path.ends_with("Set 3D Cursor location"):
		line_edit = set_3d_cursor_location_line_edit
		modifiers = set_3d_cursor_location_modifiers
	elif path.ends_with("Show Pie Menu"):
		line_edit = show_pie_menu_line_edit
		modifiers = show_pie_menu_modifiers
	elif path.ends_with("Create new 3D Cursor"):
		line_edit = create_new_3d_cursor_line_edit
		modifiers = create_new_3d_cursor_modifiers
	elif path.ends_with("Recover 3D Cursor"):
		line_edit = recover_3d_cursor_line_edit
		modifiers = recover_3d_cursor_modifiers

	if line_edit == null or modifiers.is_empty():
		return
	line_edit.text = shortcut.get_as_text()
	_parse_event(shortcut.events.front(), line_edit, modifiers, false, false)


func _parse_event(event: InputEvent, line_edit: LineEdit, modifier_buttons, grab_focus: bool = true, extra_info: bool = true) -> void:
	if event is InputEventMouseButton and event.button_index in [1, 2, 3]:
		line_edit.set_meta("shortcut_type", Cursor3DShortcutManager.ShortcutType.MOUSE)
		line_edit.set_meta("keycode", event.button_index)
		var btn: String = ""
		match event.button_index:
			1:
				btn = "Left Mouse Button"
			2:
				btn = "Right Mouse Button"
			3:
				btn = "Middle Mouse Button"
		line_edit.text = btn
	elif event is InputEventKey:
		line_edit.set_meta("shortcut_type", Cursor3DShortcutManager.ShortcutType.KEY)
		line_edit.set_meta("keycode", event.keycode)
		var key_string = OS.get_keycode_string(event.keycode)
		var physical_string = OS.get_keycode_string(event.physical_keycode)
		var unicode_string = OS.get_keycode_string(event.unicode)
		var extra_string: String = " or {0} (Physical) or {1} (Unicode)".format(
			[physical_string, unicode_string]
		)
		var btn: String = ("{0}{1}" if extra_info else "{0}").format(
			[key_string, extra_string]
		)
		line_edit.text = btn
	modifier_buttons["alt"].button_pressed = event.alt_pressed
	modifier_buttons["shift"].button_pressed = event.shift_pressed
	modifier_buttons["ctrl"].button_pressed = event.ctrl_pressed
	if grab_focus:
		line_edit.grab_focus()


func reset_shortcuts(only_ui: bool = false) -> void:
	set_3d_cursor_location_line_edit.text = "Right Mouse Button"
	set_3d_cursor_location_line_edit.set_meta("shortcut_type", Cursor3DShortcutManager.ShortcutType.MOUSE)
	set_3d_cursor_location_line_edit.set_meta("keycode", MOUSE_BUTTON_RIGHT)
	set_3d_cursor_location_modifiers["alt"].button_pressed = false
	set_3d_cursor_location_modifiers["shift"].button_pressed = true
	set_3d_cursor_location_modifiers["ctrl"].button_pressed = false
	set_3d_cursor_location_modifiers["windows"].button_pressed = false
	set_3d_cursor_location_modifiers["auto_remap"].button_pressed = false

	show_pie_menu_line_edit.text = "S or S (Physical) or S (Unicode)"
	show_pie_menu_line_edit.set_meta("shortcut_type", Cursor3DShortcutManager.ShortcutType.KEY)
	set_3d_cursor_location_line_edit.set_meta("keycode", KEY_S)
	show_pie_menu_modifiers["alt"].button_pressed = false
	show_pie_menu_modifiers["shift"].button_pressed = true
	show_pie_menu_modifiers["ctrl"].button_pressed = false
	show_pie_menu_modifiers["windows"].button_pressed = false
	show_pie_menu_modifiers["auto_remap"].button_pressed = false

	create_new_3d_cursor_line_edit.text = "Right Mouse Button"
	create_new_3d_cursor_line_edit.set_meta("shortcut_type", Cursor3DShortcutManager.ShortcutType.MOUSE)
	create_new_3d_cursor_line_edit.set_meta("keycode", MOUSE_BUTTON_RIGHT)
	create_new_3d_cursor_modifiers["alt"].button_pressed = false
	create_new_3d_cursor_modifiers["shift"].button_pressed = true
	create_new_3d_cursor_modifiers["ctrl"].button_pressed = true
	create_new_3d_cursor_modifiers["windows"].button_pressed = false
	create_new_3d_cursor_modifiers["auto_remap"].button_pressed = false

	recover_3d_cursor_line_edit.text = "Right Mouse Button"
	recover_3d_cursor_line_edit.set_meta("shortcut_type", Cursor3DShortcutManager.ShortcutType.MOUSE)
	recover_3d_cursor_line_edit.set_meta("keycode", MOUSE_BUTTON_RIGHT)
	recover_3d_cursor_modifiers["alt"].button_pressed = true
	recover_3d_cursor_modifiers["shift"].button_pressed = true
	recover_3d_cursor_modifiers["ctrl"].button_pressed = false
	recover_3d_cursor_modifiers["windows"].button_pressed = false
	recover_3d_cursor_modifiers["auto_remap"].button_pressed = false

	if not only_ui:
		shortcut_manager.hard_reset_shortcuts()


func _get_shortcut_from_meta(line_edit: LineEdit, modifiers: Dictionary) -> Dictionary:
	if not line_edit.has_meta("shortcut_type"):
		return {}
	if not line_edit.has_meta("keycode"):
		return {}
	if not line_edit.has_meta("shortcut_name"):
		return {}
	var shortcut_type: Cursor3DShortcutManager.ShortcutType = line_edit.get_meta("shortcut_type")
	var keycode: int = line_edit.get_meta("keycode")
	var shortcut = shortcut_manager.create_shortcut(
		shortcut_type,
		keycode,
		modifiers["alt"].button_pressed,
		modifiers["shift"].button_pressed,
		modifiers["ctrl"].button_pressed,
		modifiers["windows"].button_pressed,
		modifiers["auto_remap"].button_pressed
	)
	return { Cursor3DShortcutManager.shortcut_path + line_edit.get_meta("shortcut_name"): shortcut }


func apply_shortcuts() -> void:
	var shortcut_type: Cursor3DShortcutManager.ShortcutType
	if set_3d_cursor_location_line_edit.has_meta("shortcut_type"):
		shortcut_type = set_3d_cursor_location_line_edit.get_meta("shortcut_type")
	var shortcuts: Dictionary[String, Shortcut] = {}
	shortcuts.merge(_get_shortcut_from_meta(
		set_3d_cursor_location_line_edit,
		set_3d_cursor_location_modifiers
	))
	shortcuts.merge(_get_shortcut_from_meta(
		show_pie_menu_line_edit,
		show_pie_menu_modifiers
	))
	shortcuts.merge(_get_shortcut_from_meta(
		create_new_3d_cursor_line_edit,
		create_new_3d_cursor_modifiers
	))
	shortcuts.merge(_get_shortcut_from_meta(
		recover_3d_cursor_line_edit,
		recover_3d_cursor_modifiers
	))

	shortcut_manager.apply_shortcuts(shortcuts)


func _on_shortcut_section_toggle_button_toggled(toggled_on: bool) -> void:
	shortcuts.visible = not toggled_on
	shortcut_section_toggle_button.text = "Hide Shortcuts" if shortcuts.visible else "Show Shortcuts"


func _on_reset_button_pressed() -> void:
	reset_shortcuts()
