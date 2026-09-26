extends Button

signal hovering_started
signal hovering_ended
signal clicked

@onready var container: CenterContainer = $CenterContainer
@onready var inv = Utils.get_inventory()

var itemStackUI: InvItemStackUi
var index: int

func insert(isu: InvItemStackUi):
	itemStackUI = isu
	container.add_child(itemStackUI)
	
	if !itemStackUI.invSlot or inv.items[index] == itemStackUI.invSlot: return
	
	inv.insertSlot(index, itemStackUI.invSlot)

func takeItem():
	var item = itemStackUI
	
	container.remove_child(itemStackUI)
	itemStackUI = null
	
	return item

func isEmpty():
	return !itemStackUI

func _on_mouse_entered() -> void:
	hovering_started.emit(self)

func _on_mouse_exited() -> void:
	hovering_ended.emit()

func _on_focus_entered() -> void:
	hovering_started.emit(self)

func _on_focus_exited() -> void:
	hovering_ended.emit()

func _on_pressed() -> void:
	clicked.emit(self)
