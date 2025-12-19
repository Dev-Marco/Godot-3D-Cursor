@tool
class_name DragAndDropItemList
extends ItemList

var _linked_items: Array[Node] = []


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false

	if not data.has("nodes"):
		return false

	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var nodes: Array[Node] = []
	nodes.assign((data["nodes"] as Array).map(get_node))
	for node: Node in nodes:
		if node in _linked_items:
			continue
		_linked_items.append(node)
		add_item(node.name)
