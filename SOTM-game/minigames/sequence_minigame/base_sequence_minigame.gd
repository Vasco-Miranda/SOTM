extends MinigameLevel

@onready var green = $NinePatchRect/VBoxContainer/OptionsContainer/GreenButton
@onready var purple = $NinePatchRect/VBoxContainer/OptionsContainer/PurpleButton
@onready var yellow = $NinePatchRect/VBoxContainer/OptionsContainer/YellowButton
@onready var blue = $NinePatchRect/VBoxContainer/OptionsContainer/BlueButton
@onready var red = $NinePatchRect/VBoxContainer/OptionsContainer/RedButton

@onready var right1 = $NinePatchRect/VBoxContainer/Header/HBoxContainer/Right1
@onready var right2 = $NinePatchRect/VBoxContainer/Header/HBoxContainer/Right2
@onready var right3 = $NinePatchRect/VBoxContainer/Header/HBoxContainer/Right3
@onready var wrong_text = $NinePatchRect/VBoxContainer/Header/HBoxContainer/Wrong

@onready var clock = $NinePatchRect/Clock

var colors = []
var right_checks = []
var sequence = []
var player_sequence = []

var curr_round := 0
var round_lengths = [3, 5, 7]

var accepting_input := false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	colors = [
		green,
		red,
		blue,
		yellow,
		purple
	]
	right_checks = [
		right1,
		right2,
		right3
	]
	
	for button in colors:
		button.pivot_offset = button.size / 2.0
	
	green.pressed.connect(_on_color_pressed.bind(0))
	red.pressed.connect(_on_color_pressed.bind(1))
	blue.pressed.connect(_on_color_pressed.bind(2))
	yellow.pressed.connect(_on_color_pressed.bind(3))
	purple.pressed.connect(_on_color_pressed.bind(4))
	
	await get_tree().create_timer(0.5).timeout
	start_round()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func generate_sequence(length:int):
	sequence.clear()
	for i in length:
		sequence.append(randi_range(0, 4))


func start_round():
	player_sequence.clear()
	generate_sequence(round_lengths[curr_round])
	await show_sequence()
	await get_tree().create_timer(0.5).timeout
	accepting_input = true
	set_buttons_enabled(true)
	clock.visible = false


func show_sequence():
	clock.visible = true
	accepting_input = false
	set_buttons_enabled(false)
	
	await get_tree().create_timer(0.5).timeout
	for color_index in sequence:
		await button_animation(colors[color_index])


func set_buttons_enabled(enabled: bool):
	for button in colors:
		button.disabled = not enabled


func button_animation(button: Button):
	var tween = create_tween()
	
	tween.tween_property(
		button,
		"scale",
		Vector2(1.2, 1.2),
		0.3
	)
	
	tween.tween_property(
		button,
		"scale",
		Vector2.ONE,
		0.3
	)
	
	await tween.finished
	await get_tree().create_timer(0.15).timeout
	
	# previous animation:
	#
	#var button = colors[color_index]
	#button.scale = Vector2(1.2, 1.2)
	#await get_tree().create_timer(0.5).timeout
	#button.scale = Vector2.ONE
	#await get_tree().create_timer(0.25).timeout


func _on_color_pressed(color_index:int):
	if not accepting_input:
		return
	
	record_input("sequence_button")
	await button_animation(colors[color_index])
	player_sequence.append(color_index)
	var current = player_sequence.size() - 1
	
	if player_sequence[current] != sequence[current]:
		record_attempt(false, "sequence_round")
		fail_game()
		return
	
	if player_sequence.size() == sequence.size():
		record_attempt(true, "sequence_round")
		right_checks[curr_round].visible = true
		curr_round += 1
		if curr_round >= round_lengths.size():
			win_game()
		else:
			await get_tree().create_timer(1).timeout
			start_round()


func win_game():
	right.emit()


func fail_game():
	accepting_input = false
	set_buttons_enabled(false)
	wrong_text.visible = true
	await get_tree().create_timer(1).timeout
	wrong.emit()
