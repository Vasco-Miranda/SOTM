extends Node2D

@onready var timer_ui = $CanvasLayer/Timer_UI
@onready var minigame_layer = $CanvasLayer/MinigameLayer
@onready var book = $CanvasLayer/Book

var level: String = "entrance"
var curr_level_root: Node = null
var player: Player = null

var pause_menu_node: Node

var balloon: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Utils.last_room:
		level = Utils.last_room
	curr_level_root = get_node("LevelRoot")
	_load_level(level)
	
	await get_tree().process_frame
	
	player = get_tree().get_nodes_in_group("player")[0]
	Utils.apply_pending_load_state()
	player = get_tree().get_nodes_in_group("player")[0]
	player.inv = Utils.get_inventory()

	var loaded_pos = Utils.consume_pending_player_position()
	if loaded_pos != null:
		player.position = loaded_pos
	else:
		player.position = Vector2(78, 541)
	#78 541
	
	timer_ui.timed_out.connect(_on_timer_timed_out)
	Utils.apply_pending_timer_state(timer_ui)
	
	Utils.add_char(player.character)

# -----------------
# LEVEL MANAGEMENT
# -----------------
func _load_level(level_name: String) -> void:
	if curr_level_root:
		curr_level_root.queue_free()
	
	#Change level
	var level_path: String = "res://scenes/levels/%s_level.tscn" % level_name
	curr_level_root = load(level_path).instantiate()
	add_child(curr_level_root)
	
	_setup_level()
	
	# Save current level info
	curr_level_root.name = "LevelRoot"
	Utils.save_last_room(level_name)
	

func _setup_level() -> void:
	var exits = get_tree().get_nodes_in_group("exits")
	
	# Connect exits to respective rooms by their label
	for exit in exits:
		var label = exit.get_node_or_null("Label")
		exit.body_entered.connect(_on_exit_body_entered.bind(label))
	
	# Change player position depending on last level
	var positions = get_tree().get_nodes_in_group("pos")
	var last_room = Utils.get_last_room()
	var new_pos = null
	
	for pos in positions:
		if pos.name == last_room:
			new_pos = Vector2(pos.position)
	
	if new_pos and not Utils.has_pending_loaded_player_position():
		await get_tree().process_frame
		player = get_tree().get_nodes_in_group("player")[0]
		player.position = new_pos
		
	# Connect NPC interaction signal
	var NPCs = get_tree().get_nodes_in_group("NPC")
	for npc: NPC in NPCs:
		npc.begin_talk.connect(_on_begin_talk)

	Utils.sync_live_scene_characters()

# -----------------
# SIGNAL HANDLERS
# -----------------
func _on_exit_body_entered(body: Node2D, label) -> void:
	if body.name == "Player":
		if label:
			Utils.register_room_transition()
			call_deferred("_load_level", label.text)

func _on_book_closed() -> void:
	get_tree().paused = false

func _on_book_opened() -> void:
	get_tree().paused = true

func _on_begin_talk(npc: NPC) -> void:
	Utils.begin_dialogue(npc.char_name)
	balloon = DialogueManager.show_dialogue_balloon(npc.char.dialogue, "start")

func _on_pause_menu_pause() -> void:
	get_tree().paused = true
	timer_ui.pause_timer()
	if balloon:
		balloon.visible = false

func _on_pause_menu_resume() -> void:
	get_tree().paused = false
	timer_ui.resume_timer()
	if balloon:
		balloon.visible = true

func _on_timer_timed_out() -> void:
	for child in minigame_layer.get_children():
		child.free()
	minigame_layer.free()
	
	if balloon:
		balloon.will_block_other_input = false
		balloon.queue_free()
	
	get_tree().paused = false
	Utils.load_end_menu()
	


func _on_book_minigame(minigame: Minigame) -> void:
	minigame.connect("finished", _on_minigame_finished)
	minigame_layer.add_child(minigame)


func _on_minigame_finished() -> void:
	minigame_layer.get_children()[0].queue_free()


func _on_minigame_failed() -> void:
	minigame_layer.get_children()[0].queue_free()


func _on_minigame_succeeded() -> void:
	minigame_layer.get_children()[0].queue_free()
	book.inv_ui.curr_item.show_hidden_info = true
