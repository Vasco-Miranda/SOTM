extends MinigameLevel

enum Match_Type {
	WORD,
	ICON
}

@onready var options_container = $NinePatchRect/VBoxContainer/OptionsContainer

@export var type: Match_Type

@export var correct_word: String
@export var wrong_word_1: String
@export var wrong_word_2: String
@export var wrong_word_3: String

@export var correct_icon: Texture2D
@export var wrong_icon_1: Texture2D
@export var wrong_icon_2: Texture2D
@export var wrong_icon_3: Texture2D

func _ready() -> void:
	randomize()
	var options
	
	match type:
		Match_Type.WORD:
			options = [
				correct_word,
				wrong_word_1,
				wrong_word_2,
				wrong_word_3
			]
		Match_Type.ICON:
			options = [
				correct_icon,
				wrong_icon_1,
				wrong_icon_2,
				wrong_icon_3
			]
	options.shuffle()
	
	var buttons = options_container.get_children()
	
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		var option = options[i]
		
		match type:
			Match_Type.WORD:
				button.text = option
				
				if option == correct_word:
					button.pressed.connect(_on_correct_answer)
				else:
					button.pressed.connect(_on_wrong_answer)
			Match_Type.ICON:
				button.text = ""
				button.icon = option
				
				if option == correct_icon:
					button.pressed.connect(_on_correct_answer)
				else:
					button.pressed.connect(_on_wrong_answer)


func _on_correct_answer():
	record_attempt(true, "match_answer")
	right.emit()


func _on_wrong_answer():
	record_attempt(false, "match_answer")
	wrong.emit()
