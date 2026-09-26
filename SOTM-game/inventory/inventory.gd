extends Resource

class_name Inv

signal updated

@export var items: Array[InvItem]
var item_names: Array[String] = []

func insert(item: InvItem):
	for i in range(items.size()):
		if !items[i]:
			items[i] = item
			item_names.append(item.name)
			break
	updated.emit()

func removeItemAtIndex(i: int):
	items[i] = null

func insertSlot(i: int, item: InvItem):
	var oldI = items.find(item)
	removeItemAtIndex(oldI)
	items[i] = item

func has_item(item: String):
	return item_names.has(item)

func get_item(item_name: String) -> InvItem:
	for item in items:
		if item != null and item.name == item_name:
			return item
	return null

func get_item_by_clue(clue_id: String) -> InvItem:
	for item in items:
		if item != null and item.get_clue_id() == clue_id:
			return item
	return null

func has_clue(clue_id: String) -> bool:
	return get_item_by_clue(clue_id) != null

func has_revealed_clue(clue_id: String) -> bool:
	var item := get_item_by_clue(clue_id)
	return item != null and item.show_hidden_info

func rebuild_item_names() -> void:
	item_names.clear()
	for item in items:
		if item != null:
			item_names.append(item.name)

func apply_state(saved_items: Array, saved_item_names: Array = []) -> void:
	items = saved_items.duplicate(true)
	item_names = []

	if saved_item_names.is_empty():
		rebuild_item_names()
	else:
		for item_name in saved_item_names:
			item_names.append(str(item_name))

	updated.emit()

func clear_inventory() -> void:
	var slot_count := items.size()
	items.clear()
	for _i in range(slot_count):
		items.append(null)

	item_names.clear()
	updated.emit()
