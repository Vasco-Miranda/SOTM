extends Resource

class_name InvItem

@export var name: String = ""
@export var clue_id: String = ""
@export var texture: Texture2D
@export var description: String = ""
@export var hidden_info: String = ""
@export var minigame: PackedScene

@export var show_hidden_info: bool = false
@export var inspected: bool = false

func unhide_info() -> void:
	show_hidden_info = true

func get_description() -> String:
	if show_hidden_info:
		return hidden_info
	else:
		return description

func get_clue_id() -> String:
	if clue_id != "":
		return clue_id

	var clue_map := {
		"Bloody knife": "knife",
		"Candlestick": "candlestick",
		"Letter opener": "opener",
		"Medication bottle": "meds",
		"Criptic note": "note",
		"Stained glove": "glove",
		"Wine glass": "wine"
	}

	return clue_map.get(name, "")


func connect_signals(minigame_instance: Minigame) -> void:
	minigame_instance.connect("succeeded", _on_minigame_success)
	minigame_instance.connect("failed", _on_minigame_failed)


func _on_minigame_success():
	unhide_info()


func _on_minigame_failed():
	print("FAIL")
