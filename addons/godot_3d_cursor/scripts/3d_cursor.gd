@tool
class_name Cursor3D
extends Marker3D

## The size of the 3D Cursor within your scene
@export var size_scale: float = 1.0

@export_group("Label Settings")
## This setting decides whether the label with the text '3D Cursor' should
## be displayed
@export var show_label: bool = true
## This setting decides whether the label should scale with the selected size
## of the 3D Cursor.
@export var scale_affect_label: bool = false

# The standard scale of the 3D Cursor. This size is chosen because of the
# size of the .png used for the cursor. Please don't touch (private var)
var _scale: float = 0.25

## The sprite of the 3D Cursor
@onready var sprite_3d: Sprite3D = $Sprite3D
## The label of the 3D Cursor
@onready var label_3d: Label3D = $Sprite3D/Label3D


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		hide()

	# No manual user input allowed on rotation and scale;
	# Reset any user input to 0 or 1 respectively
	rotation = Vector3.ZERO
	scale = Vector3.ONE

	# Show the label if desired
	label_3d.visible = show_label

	# Set the scale of the 3D Cursor
	sprite_3d.scale = Vector3(_scale * size_scale, _scale * size_scale, _scale * size_scale)
	if scale_affect_label:
		label_3d.scale = Vector3.ONE * 4
	else:
		var label_scale = 1 / (_scale * size_scale)
		label_3d.scale = Vector3(label_scale, label_scale, label_scale)
