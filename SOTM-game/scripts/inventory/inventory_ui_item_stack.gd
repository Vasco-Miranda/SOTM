extends Panel

class_name InvItemStackUi

@onready var item_visual: Sprite2D = $Item_Display

var invSlot: InvItem

func update():
	if !invSlot : return
	
	item_visual.texture = invSlot.texture
	item_visual.visible = true
	
