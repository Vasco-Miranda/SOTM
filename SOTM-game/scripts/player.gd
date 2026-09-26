extends CharacterBody2D
class_name Player

const SPEED = 300.0
var last_dir: Vector2 = Vector2.DOWN
var is_locked: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var inv: Inv
@export var character: Character

func _physics_process(_delta: float) -> void:
	if is_locked:
		velocity = Vector2.ZERO
	else:
		process_movement()
	process_animation()
	move_and_slide()

func process_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_dir = direction
	else:
		velocity = Vector2.ZERO

func process_animation() -> void:
	if velocity != Vector2.ZERO:
		play_animation("run", last_dir)
	else:
		play_animation("idle", last_dir)

func play_animation(prefix: String ,dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right" + '1')
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up" + '1')
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down" + '1')
	
func has_item(item: String):
	return inv.has_item(item)

func has_clue(clue_id: String) -> bool:
	return inv.has_clue(clue_id)

func has_revealed_clue(clue_id: String) -> bool:
	return inv.has_revealed_clue(clue_id)
