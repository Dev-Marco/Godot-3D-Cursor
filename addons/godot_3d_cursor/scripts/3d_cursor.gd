@tool
class_name Cursor3D
extends Marker3D

## The size of the [Cursor3D] within your scene
var size_scale: float = 1.0:
	set(value):
		size_scale = value
		set_meta("size_scale", value)
## This setting decides whether the label with the text '3D Cursor' should
## be displayed
var show_title_label: bool = true:
	set(value):
		show_title_label = value
		set_meta("show_title_label", value)
## This setting decides whether the number label should be displayed
var show_number_label: bool = true:
	set(value):
		show_number_label = value
		set_meta("show_number_label", value)
## This setting decides whether the label should scale with the selected size
## of the [Cursor3D].
var scale_affect_labels: bool = true:
	set(value):
		scale_affect_labels = value
		set_meta("scale_affect_labels", value)
## The reference to the plugin core.
var plugin_context: Plugin3DCursor:
	set(context):
		plugin_context = context
		_connect_signals()
var signal_hub: Cursor3DSignalHub:
	get:
		if plugin_context == null:
			return null
		return plugin_context.signal_hub
## The ID of the cursor
var cursor_id: int = -1

# The standard scale of the 3D Cursor. This size is chosen because of the
# size of the .png used for the cursor. Please don't touch (private var)
var _scale: float = 0.25
var _initialized: bool = false
var _selected: bool = false

var _normal_color: Color = Color.hex(0xD9B500FF)
var _active_color: Color = Color.DARK_ORANGE
var _selected_color: Color = Color.hex(0x00F2FFFF)

## The sprite of the [Cursor3D]
@onready var sprite_3d: Sprite3D = $Sprite3D
## The label of the [Cursor3D].
@onready var title_label: Label3D = $Sprite3D/TitleLabel
## The number label of the [Cursor3D].
@onready var number_label: Label3D = $Sprite3D/NumberLabel


func _init() -> void:
	if not Engine.is_editor_hint():
		return
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)


func _enter_tree() -> void:
	if has_meta("cursor_id"):
		cursor_id = get_meta("cursor_id")
	if has_meta("size_scale"):
		size_scale = get_meta("size_scale")
	if has_meta("show_title_label"):
		show_title_label = get_meta("show_title_label")
	if has_meta("show_number_label"):
		show_number_label = get_meta("show_number_label")
	if has_meta("scale_affect_labels"):
		scale_affect_labels = get_meta("scale_affect_labels")
	set_meta("_edit_lock_", true)


func _process(delta: float) -> void:
	# When the game is running hide the cursor
	if not Engine.is_editor_hint():
		hide()
	# If the plugin is disabled remove the cursor
	if Engine.is_editor_hint() and not EditorInterface.is_plugin_enabled("godot_3d_cursor"):
		queue_free()

	if not _initialized and cursor_id != -1:
		number_label.text = "#{0}".format([cursor_id])
		_initialized = true

	# No manual user input allowed on rotation and scale;
	# Reset any user input to 0 or 1 respectively
	rotation = Vector3.ZERO
	scale = Vector3.ONE

	# Show the labels if desired
	title_label.visible = show_title_label
	number_label.visible = show_number_label

	# Set the scale of the 3D Cursor
	sprite_3d.scale = Vector3(_scale * size_scale, _scale * size_scale, _scale * size_scale)
	# Scale the labels alongside the cursor
	if scale_affect_labels:
		title_label.scale = Vector3.ONE * 4
		number_label.scale = Vector3.ONE * 4
	else:
		var label_scale = 1 / (_scale * size_scale)
		title_label.scale = Vector3(label_scale, label_scale, label_scale)
		number_label.scale = Vector3(label_scale, label_scale, label_scale)

	if plugin_context == null:
		return

	if _selected:
		_apply_color(_selected_color) # Blue Color
		return
	if plugin_context.cursor == self:
		_apply_color(_active_color)
		return
	_apply_color(_normal_color) # Yellow Color


## Sets up the [member Cursor3D.plugin_context]
func setup(plugin_context: Plugin3DCursor, cursor_id: int) -> void:
	self.plugin_context = plugin_context
	self.cursor_id = cursor_id
	set_meta("cursor_id", cursor_id)
	set_meta("size_scale", size_scale)
	set_meta("show_title_label", show_title_label)
	set_meta("show_number_label", show_number_label)
	set_meta("scale_affect_labels", scale_affect_labels)
	visibility_changed.connect(_on_visibility_changed)

	_set_normal_color(plugin_context.settings_dock.cursor_normal_color)
	_set_active_color(plugin_context.settings_dock.cursor_active_color)
	_set_selected_color(plugin_context.settings_dock.cursor_selected_color)


func _connect_signals() -> void:
	if not signal_hub.cursor_normal_color_changed.is_connected(_set_normal_color):
		signal_hub.cursor_normal_color_changed.connect(_set_normal_color)
	if not signal_hub.cursor_active_color_changed.is_connected(_set_active_color):
		signal_hub.cursor_active_color_changed.connect(_set_active_color)
	if not signal_hub.cursor_selected_color_changed.is_connected(_set_selected_color):
		signal_hub.cursor_selected_color_changed.connect(_set_selected_color)


func _on_visibility_changed() -> void:
	if plugin_context == null:
		return
	if plugin_context.cursor != self:
		return
	plugin_context.settings_dock.toggle_action_buttons_for_disabled_cursor()
	plugin_context.settings_dock.set_toggle_cursor_button_label()


func _on_selection_changed() -> void:
	if plugin_context == null:
		return
	_selected = self in plugin_context.editor_selection.get_selected_nodes()


func _apply_color(color: Color) -> void:
	number_label.modulate = color


func _set_normal_color(color: Color) -> void:
	_normal_color = color


func _set_active_color(color: Color) -> void:
	_active_color = color


func _set_selected_color(color: Color) -> void:
	_selected_color = color
