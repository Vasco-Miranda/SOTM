extends Control

@onready var loadSlotInput = $CenterContainer/Control/LoadSlot
@onready var menu_container = $CenterContainer/Control
@onready var options_container = $CenterContainer/OptionsContainer
@onready var models_switch = $CenterContainer/OptionsContainer/ModelsButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	models_switch.button_pressed = Utils.ai_models_on


func _on_start_pressed() -> void:
	Utils.reset_runtime_state()
	get_tree().change_scene_to_file("res://scenes/menus/intro.tscn")

func _on_load_pressed() -> void:
	var loadSlot: String = loadSlotInput.text
	if !loadSlot.is_valid_int():
		return
	if !SaveLoad._load(loadSlot):
		print("Save doesn't exist!!")
		_on_start_pressed()

func _on_options_pressed() -> void:
	options_container.visible = true
	
	for child in menu_container.get_children():
		if child.name == "LoadSlot":
			child.editable = false
		else:
			child.disabled = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_models_button_toggled(toggled_on: bool) -> void:
	Utils.ai_models_on = toggled_on


func _on_done_button_pressed() -> void:
	for child in menu_container.get_children():
		if child.name == "LoadSlot":
			child.editable = true
		else:
			child.disabled = false
	
	options_container.visible = false
