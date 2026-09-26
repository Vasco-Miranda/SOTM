extends Control

@onready var saveSlotInput = $NinePatchRect/CenterContainer/Control/SaveSlot

var is_paused = false

signal pause
signal resume

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if is_paused:
			close()
		else:
			is_paused = true
			visible = true
			pause.emit()

func close():
	visible = false
	is_paused = false
	resume.emit()

func _on_resume_pressed() -> void:
	close()


func _on_save_pressed() -> void:
	var saveSlot: String = saveSlotInput.text
	if !saveSlot.is_valid_int():
		return
	SaveLoad._save(saveSlot)


func _on_quit_pressed() -> void:
	get_tree().quit()
