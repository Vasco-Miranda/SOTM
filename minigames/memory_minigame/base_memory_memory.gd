extends MinigameLevel

@export var right_img: Texture2D
@export var wrong_img_1: Texture2D
@export var wrong_img_2: Texture2D
@export var wrong_img_3: Texture2D

@onready var options_container = $NinePatchRect/VBoxContainer/OptionsContainer
@onready var init_container = $NinePatchRect/InitContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(1).timeout
	init_container.visible = false
	await get_tree().create_timer(2).timeout
	show_options()


func show_options():
	randomize()
	var options = [
		right_img,
		wrong_img_1,
		wrong_img_2,
		wrong_img_3
	]
	options.shuffle()
	
	var buttons = options_container.get_children()
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		var option = options[i]
		
		button.get_child(0).get_child(1).texture = option
		
		if option == right_img:
			button.pressed.connect(_on_correct_answer)
		else:
			button.pressed.connect(_on_wrong_answer)
	
	options_container.visible = true


func _on_correct_answer():
	record_attempt(true, "memory_answer")
	right.emit()
	print("RIGHT")


func _on_wrong_answer():
	record_attempt(false, "memory_answer")
	wrong.emit()
	print("WRONG")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
