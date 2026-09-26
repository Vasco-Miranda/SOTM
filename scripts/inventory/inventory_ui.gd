extends Control

@onready var inv: Inv = Utils.get_inventory()
@onready var itemStackUIClass = preload("res://scenes/ui/inventory/inventory_ui_item_stack.tscn")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()
@onready var info_panel: InfoPanel = $NinePatchRect/InfoPanel
@onready var item_display = $NinePatchRect2/Display/Container/TextureRect
@onready var item_details = $NinePatchRect2/Details
@onready var inspect_button = $NinePatchRect2/Details/InspectButton

var itemInHand: InvItemStackUi
var original_slot = null
var is_open: bool = false
var mouse_dragging := false
var preview_slot = null
var curr_item: InvItem

#signal opened
#signal closed
signal minigame

func _ready():
	connectSlots()
	inv.updated.connect(update)
	update()
	close()
	#$NinePatchRect/GridContainer/slot1.grab_focus()

func connectSlots():
	for i in slots.size():
		var slot = slots[i]
		slot.index = i
		
		# Input
		slot.focus_mode = Control.FOCUS_ALL
		
		# Click and drag to organize
		#slot.button_down.connect(takeItemFromSlot.bind(slot))
		
		# Hover to see quick information (name)
		slot.hovering_started.connect(hovering_started)
		slot.hovering_ended.connect(hovering_ended)
		
		# Click to see detailed info
		slot.clicked.connect(clicked)


func open():
	visible = true
	is_open = true
	slots[0].grab_focus()


func close():
	visible = false
	is_open = false
	clear_item_info()


func update():
	for slot in slots:
		if slot.itemStackUI:
			slot.itemStackUI.queue_free()
			slot.itemStackUI = null

	for i in range(min(inv.items.size(), slots.size())):
		var invSlot: InvItem = inv.items[i]
		
		if !invSlot: continue
		
		# invSlot.connect_signals()
		
		var itemStackUI: InvItemStackUi = slots[i].itemStackUI
		if !itemStackUI:
			itemStackUI = itemStackUIClass.instantiate()
			slots[i].insert(itemStackUI)
		
		itemStackUI.invSlot = invSlot
		itemStackUI.update()


func hovering_started(slot) -> void:
	if !slot.itemStackUI: return
	info_panel.display(slot.itemStackUI.invSlot)


func hovering_ended() -> void:
	info_panel.visible = false


func clicked(slot):
	if slot.itemStackUI:
		var item = slot.itemStackUI.invSlot
		curr_item = item
		
		item_display.texture = item.texture
		item_details.visible = true
		
		var info_panels = item_details.get_children()
		var name_panel: InfoPanel = info_panels[0]
		name_panel.display(item)
		var description_panel: InfoPanel = info_panels[1]
		description_panel.display_desc(item)
		
		inspect_button.disabled = item.inspected
		inspect_button.visible = not item.inspected
	else:
		clear_item_info()


func clear_item_info():
	item_display.texture = null
	
	item_details.visible = false
	
	var info_panels = item_details.get_children()
	var name_panel: InfoPanel = info_panels[0]
	name_panel.clear()
	var description_panel: InfoPanel = info_panels[1]
	description_panel.clear()
	

func update_item_info():
	var info_panels = item_details.get_children()
	var description_panel: InfoPanel = info_panels[1]
	description_panel.display_desc(curr_item)
	
	curr_item.inspected = true
	inspect_button.disabled = true
	inspect_button.visible = false

func _on_button_pressed() -> void:
	var minigame_instance: Minigame = curr_item.minigame.instantiate()
	minigame_instance.configure_for_item(curr_item)
	minigame.emit(minigame_instance)
	minigame_instance.finished.connect(update_item_info)
	
	# CONNECT MINIGAME
	curr_item.connect_signals(minigame_instance)
