extends Node

const save_location = "user://SaveFile"
var save_slot: String = '1'

var SaveFileData: SaveData = SaveData.new()

#func _ready() -> void:
#	_load()

func _save(slot: String = '0'):
	if slot != '0':
		save_slot = slot
	
	# 1. Lock and change cursor to indicate loading
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	Input.set_default_cursor_shape(Input.CURSOR_WAIT)
	# Force a frame update so the mouse mode change applies visually
	await get_tree().process_frame
	
	SaveFileData.update_data()
	var error = ResourceSaver.save(SaveFileData, save_location + str(save_slot) + ".tres")
	# 4. Handle errors (optional)
	if error != OK:
		print("Save failed!")
	else:
		print("Save successful")
	
	# 5. Restore mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _load(slot: String = '0') -> bool:
	if slot != '0':
		save_slot = slot
	var path = save_location + save_slot + ".tres"
	if FileAccess.file_exists(path):
		SaveFileData = ResourceLoader.load(path).duplicate(true)
		SaveFileData.load_data()
		return true
	return false
