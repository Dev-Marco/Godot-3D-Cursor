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

## The value at which the buttons start to animate/slide if the menu is shown
var slide_start: int = 0
## The position the buttons animate/slide to
var slide_end: int = 100
## The radius of the menu. The buttons are aligned around an invisible circle
## and this is the corresponding radius.
var menu_radius: int = slide_start
## The buttons that are "loaded"
var buttons: Array[Button] = []


func _process(delta: float) -> void:
	#var viewport_height: int = get_viewport().size.y
	#var viewport_width: int = get_viewport().size.x

	# If the menu is shown animate the buttons
	if visible:
		menu_radius = lerp(menu_radius, slide_end, 20 * delta)

	# Reset the button positions when the menu is hidden
	if not visible:
		menu_radius = slide_start

	_align_buttons()

	# Load all children from the pie menu
	var children = get_children()
	# Get all the children that are buttons if there are no new button return
	if children.filter(_is_button) == buttons:
		return

	# If there are new buttons repopulate the buttons list and display them
	buttons.clear()
	for button in children.filter(_is_button):
		buttons.append(button)

	_align_buttons()


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


## Connected to the corresponding UI button this method acts as a repeater
## by emitting the corresponding signal classes can listen to via a [PieMenu]
## instance
func _on_3d_cursor_to_selected_objects_pressed() -> void:
	hide()
	cursor_to_selected_objects_pressed.emit()


## Connected to the corresponding UI button this method acts as a repeater
## by emitting the corresponding signal classes can listen to via a [PieMenu]
## instance
func _on_selected_object_to_3d_cursor_pressed() -> void:
	hide()
	selected_object_to_cursor_pressed.emit()


## Connected to the corresponding UI button this method acts as a repeater
## by emitting the corresponding signal classes can listen to via a [PieMenu]
## instance
func _on_remove_3d_cursor_from_scene_pressed() -> void:
	hide()
	remove_cursor_from_scene_pressed.emit()


## This method is a little helper that is used to prevent some quirky behaviour
## with the consumption of events. It checks whether the user clicked on a
## button rather than the space around it
func hit_any_button() -> bool:
	var mouse_position: Vector2 = get_global_mouse_position()
	for button in buttons:
		if button.get_global_rect().has_point(mouse_position):
			return true
	return false