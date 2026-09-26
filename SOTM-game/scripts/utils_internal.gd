extends RefCounted

static func initialize_singletons(inventory: Inv) -> Dictionary:
	var drama_manager: DramaManager = preload("res://scripts/DM/drama_manager.gd").new()
	drama_manager.init(get_characters(), get_clues())
	var player_model: PlayerModel = drama_manager.player_model
	player_model.PLAYER_INV = inventory

	return {
		"drama_manager": drama_manager,
		"player_model": player_model
	}

static func rebind_runtime_state(
	drama_manager: DramaManager,
	player_model: PlayerModel,
	inventory: Inv,
	scene_tree: SceneTree
) -> Dictionary:
	if drama_manager == null or player_model == null:
		var singletons := initialize_singletons(inventory)
		drama_manager = singletons["drama_manager"]
		player_model = singletons["player_model"]

	drama_manager.player_model = player_model
	player_model.PLAYER_INV = inventory

	var players := scene_tree.get_nodes_in_group("player")
	if not players.is_empty():
		players[0].inv = inventory

	return {
		"drama_manager": drama_manager,
		"player_model": player_model
	}

static func apply_saved_characters(saved_characters: Array, scene_tree: SceneTree) -> Array[Character]:
	var restored_characters: Array[Character] = []
	var live_characters := get_live_scene_character_map(scene_tree)

	for saved_char_any in saved_characters:
		var saved_char := saved_char_any as Character
		if saved_char == null:
			continue

		var char_name := saved_char.name
		var restored_char := saved_char.duplicate(true)
		if live_characters.has(char_name):
			var live_char: Character = live_characters[char_name]
			copy_character_state(live_char, restored_char)
			restored_characters.append(live_char)
		else:
			restored_characters.append(restored_char)

	return restored_characters

static func sync_live_scene_characters(characters: Array[Character], scene_tree: SceneTree) -> void:
	var live_characters := get_live_scene_character_map(scene_tree)

	for char_name in live_characters.keys():
		var saved_index := find_character_index_by_name(characters, char_name)
		if saved_index == -1:
			continue

		var live_char: Character = live_characters[char_name]
		var saved_char: Character = characters[saved_index]
		if live_char == null or saved_char == null:
			continue

		copy_character_state(live_char, saved_char)
		characters[saved_index] = live_char

static func get_live_scene_character_map(scene_tree: SceneTree) -> Dictionary:
	var live_characters := {}
	for npc_node in scene_tree.get_nodes_in_group("NPC"):
		if npc_node == null or npc_node.char == null:
			continue
		live_characters[npc_node.char.name] = npc_node.char
	return live_characters

static func copy_character_state(target: Character, source: Character) -> void:
	target.apply_saved_state(source.get_saved_state())

static func find_character_index_by_name(characters: Array[Character], char_name: String) -> int:
	for i in range(characters.size()):
		if characters[i] != null and characters[i].name == char_name:
			return i
	return -1

static func refresh_dialogue_context(
	drama_manager: DramaManager,
	character: Character,
	npc,
	ai_models_on: bool,
	character_name: String = ""
) -> Dictionary:
	if !ai_models_on:
		return drama_manager.get_default_ctx()
	
	var resolved_name := character_name
	if resolved_name == "" and npc != null:
		resolved_name = npc.char_name

	drama_manager.sync_character_feelings(character, resolved_name)
	return drama_manager.get_dialogue_context(resolved_name)

static func get_clue_topic_key(clue_id: String, phase: String) -> String:
	return "%s_%s" % [clue_id, phase]

static func split_tags(tags_csv: String) -> Array[String]:
	var tags: Array[String] = []
	for raw_tag in tags_csv.split(",", false):
		var tag := raw_tag.strip_edges()
		if tag != "":
			tags.append(tag)
	return tags

static func consume_dialogue_choice_time(last_choice_timestamp_ms: int) -> Dictionary:
	var now := Time.get_ticks_msec()
	if last_choice_timestamp_ms == 0:
		return {
			"elapsed": 0.0,
			"timestamp_ms": now
		}

	return {
		"elapsed": maxf(0.0, float(now - last_choice_timestamp_ms) / 1000.0),
		"timestamp_ms": now
	}

static func get_characters() -> Array:
	return ["Vicenzo Miletto", "Silvia Netti", "Richie Thorne", "Ryu Imada", "Lucille Lafleur", "Emilie Vale", "Edgar Voss"]

static func get_clues() -> Array:
	return ["knife", "candlestick", "opener", "meds", "glove", "wine", "note"]
