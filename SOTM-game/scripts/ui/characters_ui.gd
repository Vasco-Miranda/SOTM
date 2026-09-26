extends Control

@onready var slots: Array = $NinePatchRect/GridContainer.get_children()
@onready var info_panel: InfoPanel = $NinePatchRect/InfoPanel
@onready var char_display = $NinePatchRect2/Display/Container/TextureRect
@onready var char_details = $NinePatchRect2/Details
@onready var notepad = $Notepad
@onready var notes_text = $Notepad/TextEdit

var is_open: bool = false
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
	
	connectSlots()

func connectSlots():
	for i in slots.size():
		var slot = slots[i]
		#slot.index = i
		
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
		var info_panels = char_details.get_children()
		var name_panel: InfoPanel = info_panels[0]
		name_panel.display_char(character)
		
		var description_label = info_panels[1]
		description_label.text = display_char_desc()
	else:
		clear_char_info()

func clear_char_info():
	char_display.texture = null
	
	char_details.visible = false
	
	var info_panels = char_details.get_children()
	var name_panel: InfoPanel = info_panels[0]
	name_panel.clear()
	
	var description_label = info_panels[1]
	description_label.text = ''

func display_char_desc():
	var info: Array = character.char_info.get_display_data()
	var new_str: String = character.char_info.description + '\n\n'
	
	for entry in info:
		new_str += "%s: %s" % [entry.label, entry.value] + '\n'
	
	return new_str


func _on_add_note_button_pressed() -> void:
	if !character: return
	notepad.visible = true
	if character.notes != "":
		notes_text.text = character.notes

func _on_close_notes_button_pressed() -> void:
	character.notes = notes_text.text
	notepad.visible = false
	notes_text.text = ""
