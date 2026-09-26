extends Control

@onready var msg1 = $NinePatchRect/Message1
@onready var msg2 = $NinePatchRect/Message2
@onready var msg3 = $NinePatchRect/Message3
@onready var msg4 = $NinePatchRect/Message4

var curr_msg
var i: int

var last_msg := false
var waiting_next := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	curr_msg = msg1
	i = 1
	show_msg()

func show_msg() -> void:
	var curr_label = curr_msg.get_child(0)
	var label_next = curr_msg.get_child(1)
	curr_msg.visible = true
	curr_label.visible = true
	label_next.visible = false
	curr_label.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(
		curr_label,
		"modulate:a",
		1.0,
		0.5
	)
	await tween.finished
	await get_tree().create_timer(1.5).timeout
	
	label_next.visible = true
	waiting_next = true
	
	var blink_tween := create_tween()
	blink_tween.set_loops()

	blink_tween.tween_property(
		label_next,
		"modulate:a",
		0.3,
		0.8
	)
	blink_tween.tween_property(
		label_next,
		"modulate:a",
		1.0,
		0.8
	)


func hide_msg() -> void:
	var tween = create_tween()
	tween.tween_property(
		curr_msg,
		"modulate:a",
		0.0,
		0.4
	)
	await tween.finished
	curr_msg.visible = false
	
	match i:
		1: 
			curr_msg = msg2
		2:
			curr_msg = msg3
		3:
			curr_msg = msg4
		4:
			last_msg = true
	i += 1


func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_gui_input(event: InputEvent) -> void:
	if waiting_next and event is InputEventMouseButton and event.pressed:
		waiting_next = false
		await hide_msg()
		
		if last_msg:
			start_game()
		else:
			show_msg()
