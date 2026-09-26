extends Control

@onready var slots: Array = $NinePatchRect/Suspects/GridContainer.get_children()
@onready var info_panel: InfoPanel = $NinePatchRect/Suspects/InfoPanel
@onready var char_display = $NinePatchRect/Character/Display/TextureRect
@onready var char_details = $NinePatchRect/Character/Details
@onready var name_panel: InfoPanel = $NinePatchRect/Character/Details/InfoPanel_name
@onready var notes_label = $NinePatchRect/Character/Details/CharNotes
@onready var description_label = $NinePatchRect/Character/Details/CharDescription

var character: Character

func _ready() -> void:
	update()
	connectSlots()
	Utils.chars_updated.connect(update)

func update():
	var chars = Utils.characters
	
	for i in chars.size():
		var curr_char = chars[i]
		if !slots.has(curr_char):
			slots[i].insert(chars[i])

func connectSlots():
	for i in slots.size():
		var slot = slots[i]
		
		# Hover to see quick information (name)
		slot.hovering_started.connect(hovering_started)
		slot.hovering_ended.connect(hovering_ended)
		
		# Click to see detailed info
		slot.clicked.connect(clicked)

func hovering_started(slot) -> void:
	if !slot.char: return
	info_panel.display_char(slot.char)

func hovering_ended() -> void:
	info_panel.visible = false
	info_panel.clear()
	
func clicked(slot):
	if slot.char:
		character = slot.char
		char_display.texture = character.portrait
		
		char_details.visible = true
		name_panel.display_char(character)
		
		description_label.text = display_char_desc()
		
		notes_label.text = "Notes:\n" + character.notes
	else:
		clear_char_info()

func clear_char_info():
	character = null
	char_display.texture = null
	
	char_details.visible = false
	
	var info_panels = char_details.get_children()
	name_panel = info_panels[0]
	name_panel.clear()
	
	notes_label.text = ''
	
	description_label.text = ''

func display_char_desc():
	var info: Array = character.char_info.get_display_data()
	var new_str: String = character.char_info.description + '\n\n'
	
	for entry in info:
		new_str += "%s: %s" % [entry.label, entry.value] + '\n'
	
	return new_str


func _on_button_pressed() -> void:
	Utils.character = character
	Utils.begin_dialogue(character.name)
	DialogueManager.show_dialogue_balloon(character.dialogue, "blamed")
	await DialogueManager.dialogue_ended
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
