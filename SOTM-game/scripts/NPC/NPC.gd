class_name NPC extends CharacterBody2D

signal begin_talk

@export var char_name: String
@export var char: Character

@onready var sprite = $AnimatedSprite2D

var is_close: bool = false
var player: CharacterBody2D
var is_talking: bool

func _process(_delta: float) -> void:
	if is_close and Input.is_action_just_pressed("interact") and !is_talking:
		talk()
		#char.meet()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		#label.visible = true
		is_close = true
		player = body

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		#label.visible = false
		is_close = false
		player = null

func talk() -> void:
	face_player()
	player.is_locked = true
	is_talking = true
	Utils.character = char
	Utils.npc = self
	begin_talk.emit(self)
	
func end_talk():
	player.is_locked = false
	is_talking = false
	Utils.character = null
	Utils.npc = null
	play_idle("south")

func face_player():
	if not player:
		return
	
	var dir = player.global_position - global_position
	
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			play_idle("east")
		else:
			play_idle("west")
	else:
		if dir.y > 0:
			play_idle("south")
		else:
			play_idle("north")

func play_idle(direction: String):
	sprite.play("idle_" + direction)
