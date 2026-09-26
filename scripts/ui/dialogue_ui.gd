extends Control

var is_open: bool = false

var npc: NPC

@onready var char_portrait = $NinePatchRect/Control/Portrait
@onready var char_name = $NinePatchRect2/Name

func _ready() -> void:
	close()
	
func talk(character: NPC):
	npc = character
	
	char_name.text = npc.char.name
	char_portrait.texture = npc.char.portrait
	
	#visible = true
	DialogueManager.show_example_dialogue_balloon(npc.char.dialogue, 'meet')
	is_open = true

func close():
	visible = false
	is_open = false
	
	if npc:
		await npc.end_talk()
	
	npc = null
	char_name.text = 'teste'
	char_portrait.texture = null
	
func _input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("ui_cancel"):
		close()
