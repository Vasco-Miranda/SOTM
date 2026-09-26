extends Control

signal selected

@onready var cell = $Cell

func _ready():
	pass

func _on_pressed():
	selected.emit()
	cell.disabled = true

func show_arrow(texture):
	cell.icon = texture

func reveal(texture):
	cell.icon = texture
