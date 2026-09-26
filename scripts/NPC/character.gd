class_name Character extends Resource

@export var name: String
@export var char_info: Char_Info
@export var portrait: Texture2D
@export var notes: String = ""
@export var dialogue: DialogueResource

@export var feelings: Dictionary = {
	'joy': 0, #high -> ecstasy, low -> sadness
	'interest': 0, # high -> vigilance, low -> surprise
	'apprehension': 0, # high -> fear, low -> anger
	'trust': 0 # high -> admiration, low -> loathing
}

func increase_joy(value: int = 1) -> void:
	if !Utils.ai_models_on:
		return
	if feelings.joy < 10:
		feelings.joy += value

func decrease_joy(value: int = 1) -> void:
	if !Utils.ai_models_on:
		return
	if feelings.joy > -10:
		feelings.joy -= value

func get_joy() -> int:
	if Utils.ai_models_on:
		return feelings.joy
	else:
		return 0

func increase_interest(value: int = 1) -> void:
	if !Utils.ai_models_on:
		return
	if feelings.interest < 10:
		feelings.interest += value

func decrease_interest(value: int = 1) -> void:
	if !Utils.ai_models_on:
		return
	if feelings.interest > -10:
		feelings.interest -= value

func get_interest() -> int:
	if Utils.ai_models_on:
		return feelings.interest
	else:
		return 0

func increase_apprehension(value: int = 1) -> void:
	if !Utils.ai_models_on:
		return
	if feelings.apprehension < 10:
		feelings.apprehension += value

func decrease_apprehension(value: int = 1) -> void:
	if !Utils.ai_models_on:
		return
	if feelings.apprehension > -10:
		feelings.apprehension -= value
		
func get_apprehension() -> int:
	if Utils.ai_models_on:
		return feelings.apprehension
	else:
		return 0

func increase_trust(value: int = 1) -> void:
	if !Utils.ai_models_on:
		return
	if feelings.trust < 10:
		feelings.trust += value

func decrease_trust(value: int = 1) -> void:
	if !Utils.ai_models_on:
		return
	if feelings.trust > -10:
		feelings.trust -= value

func get_trust() -> int:
	if Utils.ai_models_on:
		return feelings.trust
	else:
		return 0

func get_saved_state() -> Dictionary:
	return {
		"name": name,
		"notes": notes,
		"feelings": feelings.duplicate(true),
		"has_met": char_info.has_met,
		"dialogues": char_info.dialogues.duplicate(true)
	}

func apply_saved_state(state: Dictionary) -> void:
	notes = str(state.get("notes", notes))
	feelings = state.get("feelings", feelings).duplicate(true)
	char_info.has_met = bool(state.get("has_met", char_info.has_met))
	char_info.dialogues = state.get("dialogues", char_info.dialogues).duplicate(true)

func meet() -> void:
	char_info.meet()
	Utils.add_char(self)

func talked(new_dialogue: String):
	char_info.talked(new_dialogue)

func has_talked(some_dialogue: String):
	return char_info.has_talked(some_dialogue)
