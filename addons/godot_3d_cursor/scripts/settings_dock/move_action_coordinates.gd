@tool
class_name MoveActionCoordinates
## This class provides the state for the target coordinate preview used by the
## [MoveActiveCursorButton] in the [SettingsDock].
##
## It holds references to the [code]x[/code], [code]y[/code], and [code]z[/code]
## components and their respective [LineEdit] controls.
extends HBoxContainer

## The x coordinate. Setting it results in its [LineEdit] to display the value.
var x: float:
	set(value):
		x = value
		x_line_edit.text = "{0}".format([value])
## The y coordinate. Setting it results in its [LineEdit] to display the value.
var y: float:
	set(value):
		y = value
		y_line_edit.text = "{0}".format([value])
## The z coordinate. Setting it results in its [LineEdit] to display the value.
var z: float:
	set(value):
		z = value
		z_line_edit.text = "{0}".format([value])
## The coordinates in form of a [Vector3]. It is built dynamically via its getter.
var coordinates: Vector3:
	get:
		return Vector3(x, y, z)

## The [LineEdit] that displays the x component.
@onready var x_line_edit: LineEdit = $XLineEdit
## The [LineEdit] that displays the y component.
@onready var y_line_edit: LineEdit = $YLineEdit
## The [LineEdit] that displays the z component.
@onready var z_line_edit: LineEdit = $ZLineEdit


## Sets all components in one method call.
func set_coordinates(x: float, y: float, z: float) -> void:
	self.x = x
	self.y = y
	self.z = z
