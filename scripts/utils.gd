extends Node

signal chars_updated

const UtilsInternal = preload("res://scripts/utils_internal.gd")
const LIVE_INVENTORY: Inv = preload("res://inventory/player_inv.tres")

var last_room: String
var character: Character
var characters: Array[Character] = []

var npc
var ctx
var ai_models_on: bool = false

var drama_manager: DramaManager
var player_model: PlayerModel
var last_choice_timestamp_ms: int = 0
var pending_load_state: Dictionary = {}
var pending_player_position: Vector2 = Vector2.ZERO
var has_pending_player_position: bool = false
var pending_timer_remaining: float = 0.0
var has_pending_timer_remaining: bool = false

func save_last_room(room: String) -> void:
	last_room = room

func get_last_room() -> String:
	return last_room

func add_char(new_char: Character):
	var existing_index := UtilsInternal.find_character_index_by_name(characters, new_char.name)
	if existing_index == -1:
		characters.append(new_char)
	else:
		characters[existing_index] = new_char

	chars_updated.emit()

func _ready():
	var singletons := UtilsInternal.initialize_singletons(LIVE_INVENTORY)
	drama_manager = singletons["drama_manager"]
	player_model = singletons["player_model"]
	ctx = drama_manager.get_default_ctx()
	#add_child(drama_manager)

func reset_runtime_state() -> void:
	ctx = {}
	character = null
	npc = null
	characters.clear()
	last_room = ""
	last_choice_timestamp_ms = 0
	pending_load_state.clear()
	has_pending_player_position = false
	has_pending_timer_remaining = false
	LIVE_INVENTORY.clear_inventory()
	var singletons := UtilsInternal.initialize_singletons(LIVE_INVENTORY)
	drama_manager = singletons["drama_manager"]
	player_model = singletons["player_model"]
	ctx = drama_manager.get_default_ctx()
	chars_updated.emit()

func get_inventory() -> Inv:
	return LIVE_INVENTORY

func queue_loaded_state(state: Dictionary) -> void:
	pending_load_state = state.duplicate(true)
	last_room = str(state.get("curr_room", last_room))
	if state.has("pos"):
		pending_player_position = state["pos"]
		has_pending_player_position = true
	if state.has("timer_remaining"):
		pending_timer_remaining = float(state["timer_remaining"])
		has_pending_timer_remaining = true

func apply_pending_load_state() -> void:
	var runtime := UtilsInternal.rebind_runtime_state(drama_manager, player_model, LIVE_INVENTORY, get_tree())
	drama_manager = runtime["drama_manager"]
	player_model = runtime["player_model"]

	if pending_load_state.is_empty():
		return

	ai_models_on = bool(pending_load_state.get("ai_models_on", ai_models_on))

	ctx = drama_manager.get_default_ctx()
	if ai_models_on:
		var loaded_ctx: Dictionary = pending_load_state.get("ctx", {})
		for key in ctx.keys():
			if loaded_ctx.has(key):
				ctx[key] = loaded_ctx[key]

	var inventory_items: Array = pending_load_state.get("inventory_items", [])
	var inventory_item_names: Array = pending_load_state.get("inventory_item_names", [])
	LIVE_INVENTORY.apply_state(inventory_items, inventory_item_names)

	var saved_player_model: Dictionary = pending_load_state.get("player_model_state", {})
	if not saved_player_model.is_empty():
		player_model.emotional_state = saved_player_model.get("emotional_state", player_model.emotional_state).duplicate(true)
		player_model.social_state = saved_player_model.get("social_state", player_model.social_state).duplicate(true)
		player_model.cognitive_state = saved_player_model.get("cognitive_state", player_model.cognitive_state).duplicate(true)
		player_model.stress_markers = saved_player_model.get("stress_markers", player_model.stress_markers).duplicate(true)
		player_model.minigame_evaluations = saved_player_model.get("minigame_evaluations", player_model.minigame_evaluations).duplicate(true)
		player_model.stress_runtime = {
			"rapid_dialogue_streak": 0,
			"rapid_room_change_streak": 0,
			"last_room_change_ms": 0
		}
		player_model.PLAYER_INV = LIVE_INVENTORY

	var saved_drama: Dictionary = pending_load_state.get("drama_manager_state", {})
	if not saved_drama.is_empty():
		drama_manager.history = saved_drama.get("history", []).duplicate(true)
		drama_manager.tag_counts = saved_drama.get("tag_counts", {}).duplicate(true)
		drama_manager.character_interactions = saved_drama.get("character_interactions", {}).duplicate(true)
		drama_manager.character_accusations = saved_drama.get("character_accusations", {}).duplicate(true)
		drama_manager.clue_usage = saved_drama.get("clue_usage", {}).duplicate(true)
		drama_manager.total_decision_time = saved_drama.get("total_decision_time", 0.0)
		drama_manager.decision_count = saved_drama.get("decision_count", 0)
		drama_manager.player_model = player_model

	characters = UtilsInternal.apply_saved_characters(pending_load_state.get("characters", []), get_tree())
	chars_updated.emit()
	pending_load_state.clear()
	sync_live_scene_characters()

func sync_live_scene_characters() -> void:
	UtilsInternal.sync_live_scene_characters(characters, get_tree())
	chars_updated.emit()

func consume_pending_player_position() -> Variant:
	if not has_pending_player_position:
		return null

	has_pending_player_position = false
	return pending_player_position

func has_pending_loaded_player_position() -> bool:
	return has_pending_player_position

func get_main_timer_remaining() -> float:
	if get_tree().current_scene == null:
		return 0.0

	var timer_ui = get_tree().current_scene.get_node_or_null("CanvasLayer/Timer_UI")
	if timer_ui == null:
		return 0.0
	return timer_ui.get_time_left()

func apply_pending_timer_state(timer_ui) -> void:
	if not has_pending_timer_remaining or timer_ui == null:
		return

	has_pending_timer_remaining = false
	timer_ui.set_time_left(pending_timer_remaining)

# --- DIALOGUE FUNCTIONS ---
func begin_dialogue(character_name: String = "") -> void:
	last_choice_timestamp_ms = Time.get_ticks_msec()
	ctx = UtilsInternal.refresh_dialogue_context(drama_manager, character, npc, ai_models_on, character_name)

func register_dialogue_choice(
	choice_id: String,
	text: String,
	tags_csv: String = "",
	affinity_delta: float = 0.0,
	blame_delta: float = 0.0,
	clue: String = "",
	clue_focus: float = 0.0,
	stress_delta: float = 0.0,
	confusion_delta: float = 0.0,
	self_doubt_delta: float = 0.0
) -> Dictionary:
	var choice := Choice.new()
	choice.id = choice_id
	choice.text = text
	choice.character = npc.char_name if npc != null else ""
	choice.clue = clue
	choice.affinity_delta = affinity_delta
	choice.blame_delta = blame_delta
	choice.stress_delta = stress_delta
	choice.confusion_delta = confusion_delta
	choice.self_doubt_delta = self_doubt_delta
	choice.clue_focus = clue_focus
	choice.time_taken_weight = 0.15
	choice.expected_time = 2.2
	choice.hesitation_weight = 0.2
	choice.tags = UtilsInternal.split_tags(tags_csv)

	var choice_time := UtilsInternal.consume_dialogue_choice_time(last_choice_timestamp_ms)
	var time_taken: float = choice_time["elapsed"]
	last_choice_timestamp_ms = choice_time["timestamp_ms"]

	if !ai_models_on:
		ctx = drama_manager.get_default_ctx()
		return ctx

	player_model.register_dialogue_pacing(time_taken)
	drama_manager.process_choice(choice, time_taken)
	ctx = UtilsInternal.refresh_dialogue_context(drama_manager, character, npc, ai_models_on, choice.character)
	return ctx

func is_clue_surface_ready(clue_id: String) -> bool:
	return player_model != null \
		and player_model.has_clue(clue_id) \
		and not player_model.has_revealed_clue(clue_id) \
		and not character.has_talked(UtilsInternal.get_clue_topic_key(clue_id, "surface"))

func is_clue_hidden_ready(clue_id: String) -> bool:
	return player_model != null \
		and player_model.has_clue(clue_id) \
		and player_model.has_revealed_clue(clue_id) \
		and not character.has_talked(UtilsInternal.get_clue_topic_key(clue_id, "surface")) \
		and not character.has_talked(UtilsInternal.get_clue_topic_key(clue_id, "hidden"))

func is_clue_revisit_ready(clue_id: String) -> bool:
	return player_model != null \
		and player_model.has_clue(clue_id) \
		and player_model.has_revealed_clue(clue_id) \
		and character.has_talked(UtilsInternal.get_clue_topic_key(clue_id, "surface")) \
		and not character.has_talked(UtilsInternal.get_clue_topic_key(clue_id, "revisit"))

func mark_clue_topic(clue_id: String, phase: String) -> void:
	character.talked(UtilsInternal.get_clue_topic_key(clue_id, phase))

func register_room_transition() -> void:
	if player_model == null or !ai_models_on:
		return

	player_model.register_room_change(Time.get_ticks_msec())

func register_minigame_result(metrics: Dictionary) -> void:
	if player_model == null or !ai_models_on:
		return

	player_model.register_minigame_result(metrics)

# --- SAVE & LOAD FUNCTIONS ---
# Return player position to save game state
func get_player_pos() -> Vector2:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return Vector2.ZERO
	return players[0].position

func load_level(level_name):
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
	save_last_room(level_name)

func load_end_menu():
	get_tree().change_scene_to_file("res://scenes/menus/end_menu.tscn")
