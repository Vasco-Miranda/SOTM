extends Button

signal hovering_started
signal hovering_ended
signal clicked

@onready var portrait: TextureRect = $CenterContainer/Portrait

var char: Character

func insert(character: Character):
	char = character
	portrait.texture = character.portrait

func isEmpty():
	return !char

func _on_mouse_entered() -> void:
	hovering_started.emit(self)

func _on_mouse_exited() -> void:
	hovering_ended.emit()

func _on_focus_entered() -> void:
	hovering_started.emit(self)

func _on_focus_exited() -> void:
	hovering_ended.emit()

func _on_pressed() -> void:
	clicked.emit(self)
