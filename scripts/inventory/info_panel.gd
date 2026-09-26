extends Control
class_name InfoPanel

@onready var label: Label = $Label

func display(item: InvItem):
	label.text = item.name
	visible = true

func display_desc(item: InvItem):
	label.text = item.get_description()
	visible = true

func clear():
	label.text = ''
	visible = false

func display_char(character: Character):
	label.text = character.name
	visible = true
