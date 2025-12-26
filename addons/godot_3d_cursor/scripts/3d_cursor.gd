@tool
class_name Cursor3D
extends Marker3D

## The size of the [Cursor3D] within your scene
var size_scale: float = 1.0
## This setting decides whether the label with the text '3D Cursor' should
## be displayed
var show_title_label: bool = true
## This setting decides whether the number label should be displayed
var show_number_label: bool = true
## This setting decides whether the label should scale with the selected size
## of the [Cursor3D].
var scale_affect_labels: bool = true
## The reference to the plugin core.
var plugin_context: Plugin3DCursor

# The standard scale of the 3D Cursor. This size is chosen because of the
# size of the .png used for the cursor. Please don't touch (private var)
var _scale: float = 0.25

## The sprite of the [Cursor3D]
@onready var sprite_3d: Sprite3D = $Sprite3D
## The label of the [Cursor3D].
@onready var title_label: Label3D = $Sprite3D/TitleLabel
## The number label of the [Cursor3D].
@onready var number_label: Label3D = $Sprite3D/NumberLabel


func _process(delta: float) -> void:
	# When the game is running hide the cursor
	if not Engine.is_editor_hint():
		hide()
	# If the plugin is disabled remove the cursor
	if not EditorInterface.is_plugin_enabled("godot_3d_cursor"):
		queue_free()

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


## Sets up the [member Cursor3D.plugin_context]
func setup(plugin_context: Plugin3DCursor) -> void:
	self.plugin_context = plugin_context
