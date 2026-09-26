class_name Char_Info extends Resource

enum Blood_Type { A, B, AB, O }

@export var age: int
@export var nationality: String
@export var blood_type: Blood_Type

@export var description: String

@export var has_met: bool = false

@export var dialogues: Array[String] = []

const INFO_FIELDS = [
	"age",
	"nationality",
	"blood_type"
]

func meet():
	has_met = true

func talked(dialogue: String):
	dialogues.append(dialogue)
	
func has_talked(dialogue: String) -> bool:
	return dialogues.has(dialogue)

func get_display_data() -> Array:
	var result := []
	
	for key in INFO_FIELDS:
		var value = get(key)
		value = _format_value(key, value)
		
		result.append({
			"label": _format_label(key),
			"value": value
		})
	
	return result
	
func _format_label(key: String) -> String:
	match key:
		"blood_type": return "Blood Type"
		"age": return "Age"
		"nationality": return "Nationality"
		_: return key.capitalize()
		
func _format_value(key: String, value):
	match key:
		"blood_type":
			return Blood_Type.keys()[value]
		_:
			return str(value)
