@tool
class_name PieMenu
extends Control

## Emitted when the "3D Cursor to Origin" command is invoked through the [PieMenu]
signal cursor_to_origin_pressed
## Emitted when the "3D Cursor to Selected Object(s)" command is invoked through the [PieMenu]
signal cursor_to_selected_objects_pressed
## Emitted when the "Selected Object to 3D Cursor" command is invoked through the [PieMenu]
signal selected_object_to_cursor_pressed
## Emitted when the "Remove 3D Cursor from Scene" command is invoked through the [PieMenu]
signal remove_cursor_from_scene_pressed
## Emitted when the "Toggle 3D Cursor" command is invoked through the [PieMenu]
signal toggle_cursor_pressed

## The dimmed color for the selection indicator that is used if no button is hovered
const _dimmed_selection_indicator_color: Color = Color("8c8c8cFF")

## The value at which the buttons start to animate/slide if the menu is shown
var slide_start: int = 0
## The position the buttons animate/slide to
var slide_end: int = 100
## The radius of the menu. The buttons are aligned around an invisible circle
## and this is the corresponding radius.
var menu_radius: int = slide_start
## The buttons that are "loaded"
var buttons: Array[Button] = []

var _hovered_button: Button
var _show_menu_echo: bool = false

@onready var selection_indicator: Sprite2D = $SelectionIndicator
@onready var toggle_3d_cursor: Button = $Toggle3DCursor


func _process(delta: float) -> void:
	#var viewport_height: int = get_viewport().size.y
	#var viewport_width: int = get_viewport().size.x

	# If the menu is shown animate the buttons
	if visible:
		menu_radius = lerp(menu_radius, slide_end, 20 * delta)

	# Reset the button positions when the menu is hidden
	if not visible:
		menu_radius = slide_start
		_show_menu_echo = true

	_align_buttons()

	# Load all children from the pie menu
	var children = get_children()
	# Get all the children that are buttons if there are no new button return
	if children.filter(_is_button) == buttons:
		return

	# If there are new buttons repopulate the buttons list and display them
	buttons.clear()
	for button: Button in children.filter(_is_button):
		buttons.append(button)

	_align_buttons()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	# If the [PieMenu] is opened the selection indicator will rotate according
	# to the mouse position. If the user hovers over a button the indicator
	# will change its color to white and a more dimmed color otherwise
	if event is InputEventMouseMotion:
		# Calculate the angle of the mouse position to the x axis
		var rot: float = rad_to_deg(get_local_mouse_position().angle_to(Vector2.RIGHT)) - 45
		# Apply the rotation to the indicator
		selection_indicator.rotation_degrees = -rot

	# If the key used to open the [PieMenu] is held down while selecting hovering
	# over a button the user can invoke the buttons action by releasing the
	# key (s). This does not work if the key was released prior to hovering
	# over a button. This functionality is similar to the one in Blender
	if not event is InputEventKey:
		return

	if not event.keycode == KEY_S:
		return

	if event.is_released() and _hovered_button == null:
		_show_menu_echo = false
		return

	if _show_menu_echo and event.is_released():
		_hovered_button.pressed.emit()


## This method should be used in conjuncton with a [Array.filter] method.
## It checks whether a node inherits from Button
func _is_button(child: Node) -> bool:
	return child is Button


## This method aligns the available buttons in a circular menu by using
## some [sin] and [cos] magic
func _align_buttons() -> void:
	var button_count: int = len(buttons)
	for i in range(button_count):
		var button: Button = buttons[i]
		var theta: float = (i / float(button_count)) * TAU
		var x: float = (menu_radius * cos(theta))
		var y: float = (menu_radius * sin(theta)) - button.size.y / 2.0
		x = x - button.size.x if x < 0 else x
		button.position = Vector2(x, y)


## Connected to the corresponding UI button this method acts as a repeater
## by emitting the corresponding signal classes can listen to via a [PieMenu]
## instance
func _on_3d_cursor_to_origin_pressed() -> void:
	hide()
	cursor_to_origin_pressed.emit()

## Executes when the "3D Cursor to Origin" button is hovered
func _on_3d_cursor_to_origin_mouse_entered() -> void:
	_hovered_button = $"3DCursorToOrigin"
	_on_mouse_entered_button()

## Executes when the "3D Cursor to Origin" button is no longer hovered
func _on_3d_cursor_to_origin_mouse_exited() -> void:
	_hovered_button = null
	_on_mouse_exited_button()


## Connected to the corresponding UI button this method acts as a repeater
## by emitting the corresponding signal classes can listen to via a [PieMenu]
## instance
func _on_3d_cursor_to_selected_objects_pressed() -> void:
	hide()
	cursor_to_selected_objects_pressed.emit()

## Executes when the "3D Cursor to Selected Object(s)" button is hovered
func _on_3d_cursor_to_selected_objects_mouse_entered() -> void:
	_hovered_button = $"3DCursorToSelectedObjects"
	_on_mouse_entered_button()

## Executes when the "3D Cursor to Selected Object(s)" button is no longer hovered
func _on_3d_cursor_to_selected_objects_mouse_exited() -> void:
	_hovered_button = null
	_on_mouse_exited_button()


## Connected to the corresponding UI button this method acts as a repeater
## by emitting the corresponding signal classes can listen to via a [PieMenu]
## instance
func _on_selected_object_to_3d_cursor_pressed() -> void:
	hide()
	selected_object_to_cursor_pressed.emit()

## Executes when the "Selected Object to 3D Cursor" button is hovered
func _on_selected_object_to_3d_cursor_mouse_entered() -> void:
	_hovered_button = $SelectedObjectTo3DCursor
	_on_mouse_entered_button()

## Executes when the "Selected Object to 3D Cursor" button is no longer hovered
func _on_selected_object_to_3d_cursor_mouse_exited() -> void:
	_hovered_button = null
	_on_mouse_exited_button()


## Connected to the corresponding UI button this method acts as a repeater
## by emitting the corresponding signal classes can listen to via a [PieMenu]
## instance
func _on_remove_3d_cursor_from_scene_pressed() -> void:
	hide()
	remove_cursor_from_scene_pressed.emit()

## Executes when the "Remove 3D Cursor" button is hovered
func _on_remove_3d_cursor_from_scene_mouse_entered() -> void:
	_hovered_button = $Remove3DCursorFromScene
	_on_mouse_entered_button()

## Executes when the "Remove 3D Cursor" button is no longer hovered
func _on_remove_3d_cursor_from_scene_mouse_exited() -> void:
	_hovered_button = null
	_on_mouse_exited_button()


## Connected to the corresponding UI button this method acts as a repeater
## by emitting the corresponding signal classes can listen to via a [PieMenu]
## instance
func _on_toggle_3d_cursor_pressed() -> void:
	hide()
	toggle_cursor_pressed.emit()

## Executes when the "Disable/Enable 3D Cursor" button is hovered
func _on_toggle_3d_cursor_mouse_entered() -> void:
	_hovered_button = toggle_3d_cursor
	_on_mouse_entered_button()

## Executes when the "Disable/Enable 3D Cursor" button is hovered
func _on_toggle_3d_cursor_mouse_exited() -> void:
	_hovered_button = null
	_on_mouse_exited_button()


## This method is executed by every button of the [PieMenu]. It brightens
## the color of the selection indicator when a button is hovered.
func _on_mouse_entered_button() -> void:
	selection_indicator.modulate = Color.WHITE

## This method is executed by every button of the [PieMenu]. It dims the color
## of the selection indicator when a button is no longer hovered
func _on_mouse_exited_button() -> void:
	selection_indicator.modulate = _dimmed_selection_indicator_color


## This method is a little helper that is used to prevent some quirky behaviour
## with the consumption of events. It checks whether the user clicked on a
## button rather than the space around it
func hit_any_button() -> bool:
	var mouse_position: Vector2 = get_global_mouse_position()
	for button in buttons:
		if button.get_global_rect().has_point(mouse_position):
			return true
	return false


func change_toggle_label(visible: bool) -> void:
	toggle_3d_cursor.text = ("Disable" if visible else "Enable") + " 3D Cursor"
