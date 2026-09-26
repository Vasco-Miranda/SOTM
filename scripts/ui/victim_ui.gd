extends Control

@export var victim: Character
@export var crime: String = "The victim was found in the garage, with "\
+ "virtually nothing suspicious nearby. The body was cold, lips turning "\
+ "blue, and his white shirt was stained of blood near the collar. The body "\
+ "was removed before it was possible to analyse anything further. There were "\
+ "hairs stuck to the suit that didn't belong to the victim. "\
+ "No autopsy has been done yet."

@onready var crime_info = $NinePatchRect/Crime_description
@onready var display = $NinePatchRect2/Display/Container/TextureRect
@onready var char_name = $NinePatchRect2/Details/InfoPanel_name
@onready var char_info = $NinePatchRect2/Details/Victim_description

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	display.texture = victim.portrait
	char_name.display_char(victim)
	char_info.text = display_char_desc(victim)
	crime_info.text = crime


func display_char_desc(character: Character):
	var info: Array = character.char_info.get_display_data()
	var new_str: String = character.char_info.description + '\n\n'
	
	for entry in info:
		new_str += "%s: %s" % [entry.label, entry.value] + '\n'
	
	return new_str
