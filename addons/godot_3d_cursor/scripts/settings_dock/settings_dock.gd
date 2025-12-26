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
## The container that holds all action buttons from the settings dock.
@onready var action_buttons: GridContainer = %ActionButtons
## The button that removes all intances of [Cursor3D] from the current scene.
@onready var remove_all_cursors_from_scene_button: Button = %RemoveAllCursorsFromSceneButton
@onready var remove_active_cursor_from_scene_button: Button = %RemoveActiveCursorFromSceneButton


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

		# [COMPATIBILITY WITH 4.2]
		#EditorInterface.popup_node_selector(_assign_active_cursor, ["Cursor3D"])
		#signal_hub.active_cursor_line_edit_cursor_selected.emit(plugin_context.cursor)
		if EditorInterface.has_method("popup_node_selector"):
			EditorInterface.call("popup_node_selector", _assign_active_cursor, ["Cursor3D"])
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

	# [COMPATIBILITY WITH 4.2]
	#EditorInterface.popup_node_selector(_on_node_for_move_to_selected, ["Node3D"])
	if EditorInterface.has_method("popup_node_selector"):
		EditorInterface.call("popup_node_selector", _on_node_for_move_to_selected, ["Node3D"])


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


func _on_scale_spin_box_value_changed(value: float) -> void:
	if plugin_context.cursor == null:
		return
	plugin_context.cursor.size_scale = value


func _on_scale_affect_labels_check_box_toggled(toggled_on: bool) -> void:
	plugin_context.cursor.scale_affect_labels = toggled_on


func _on_show_title_label_check_box_toggled(toggled_on: bool) -> void:
	plugin_context.cursor.show_title_label = toggled_on


func _on_show_number_label_check_box_toggled(toggled_on: bool) -> void:
	plugin_context.cursor.show_number_label = toggled_on


func _on_raycast_mode_option_button_item_selected(index: int) -> void:
	match index:
		1:
			signal_hub.raycast_mode_changed.emit(Cursor3DRaycastEngine.RaycastMode.PHYSICSLESS)
		3:
			signal_hub.raycast_mode_changed.emit(Cursor3DRaycastEngine.RaycastMode.PHYSICS)
		_:
			pass
