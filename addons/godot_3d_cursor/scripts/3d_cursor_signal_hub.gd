class_name Cursor3DSignalHub
extends Node

## Emitted when the active cursor is being deleted.
signal active_cursor_deleted
## Emitted when a cursor is created or recovered.
signal cursor_created(cursor: Cursor3D)
signal cursor_recovered(cursor: Cursor3D)
## Emitted for example when a cursor's creation by duplicating another one is undone.
signal cursor_exited_tree(cursor: Cursor3D)

## Emitted when the "3D Cursor to Origin" command is invoked through the [PieMenu]
signal cursor_to_origin
## Emitted when the "3D Cursor to Selected Object(s)" command is invoked through the [PieMenu]
signal cursor_to_selected_objects
## Emitted when the "Selected Object to 3D Cursor" command is invoked through the [PieMenu]
signal selected_object_to_cursor
## Emitted when the "Remove 3D Cursor from Scene" command is invoked through the [PieMenu]
signal remove_active_cursor_from_scene
## Emitted when the "Remove all 3D Cursors from Scene" command is invoked.
signal remove_all_cursors_from_scene
## Emitted when the "Toggle 3D Cursor" command is invoked through the [PieMenu]
signal toggle_cursor
signal move_active_cursor_to(position: Vector3)

signal active_cursor_line_edit_clicked(double_click: bool)
signal active_cursor_line_edit_cursor_selected(cursor: Cursor3D)
signal active_cursor_line_edit_data_dropped(node_path: NodePath)
signal deselect_cursor_pressed
signal clear_cursor_pressed
signal raycast_mode_changed(raycast_mode: Cursor3DRaycastEngine.RaycastMode)
