extends Area2D

#@onready var label = $Interact
@onready var inv: Inv = Utils.get_inventory()

@export var itemRes: InvItem

var is_close: bool = false

func _ready() -> void:
	if _is_already_collected():
		queue_free()

func _on_child_entered_tree(_node: Node) -> void:
	await get_tree().process_frame
	_ready()
	#label.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_close and Input.is_action_just_pressed("interact"):
		collect()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		#label.visible = true
		is_close = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		#label.visible = false
		is_close = false

func collect():
	inv.insert(itemRes)
	queue_free()

func _is_already_collected() -> bool:
	if itemRes == null:
		return false

	if inv == null:
		return false

	if itemRes.get_clue_id() != "":
		return inv.has_clue(itemRes.get_clue_id())

	return inv.has_item(itemRes.name)
