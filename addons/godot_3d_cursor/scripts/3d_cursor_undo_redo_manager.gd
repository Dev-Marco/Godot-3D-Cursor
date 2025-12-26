class_name Cursor3DUndoRedoManager
extends Node

var plugin_context: Plugin3DCursor
var undo_redo: EditorUndoRedoManager


func _init(plugin_context: Plugin3DCursor) -> void:
	if plugin_context == null:
		push_error("The Cursor3DUndoRedoManager requires a valid instance of Plugin3DCursor and must not be null.")
	self.plugin_context = plugin_context
	undo_redo = plugin_context.get_undo_redo()


func add_action(node: Node3D, property: String, value: Variant, action_name: String = "") -> void:
	if node == null or property.is_empty() or value == null:
		return

	if action_name.is_empty():
		action_name = "Set " + property + " for " + node.name

	undo_redo.create_action(action_name)
	var old_value: Variant = node.get(property)
	undo_redo.add_do_property(node, property, value)
	undo_redo.add_undo_property(node, property, old_value)
	undo_redo.commit_action()
