extends Resource
class_name SaveData

@export var ctx: Dictionary = {}
@export var drama_manager_state: Dictionary = {}
@export var player_model_state: Dictionary = {}
@export var characters: Array[Character] = []
@export var inventory_items: Array[InvItem] = []
@export var inventory_item_names: Array[String] = []
@export var ai_models_on: bool = true

# Level data
@export var curr_room: String
@export var pos: Vector2
@export var timer_remaining: float = 0.0

func update_data():
	ctx = Utils.ctx.duplicate(true)
	characters = []
	for character in Utils.characters:
		if character == null:
			continue

		var saved_character := character.duplicate(true)
		saved_character.resource_path = ""
		characters.append(saved_character)

	ai_models_on = Utils.ai_models_on

	player_model_state = {
		"emotional_state": Utils.player_model.emotional_state.duplicate(true),
		"social_state": Utils.player_model.social_state.duplicate(true),
		"cognitive_state": Utils.player_model.cognitive_state.duplicate(true),
		"stress_markers": Utils.player_model.stress_markers.duplicate(true),
		"minigame_evaluations": Utils.player_model.minigame_evaluations.duplicate(true)
	}

	drama_manager_state = {
		"history": Utils.drama_manager.history.duplicate(true),
		"tag_counts": Utils.drama_manager.tag_counts.duplicate(true),
		"character_interactions": Utils.drama_manager.character_interactions.duplicate(true),
		"character_accusations": Utils.drama_manager.character_accusations.duplicate(true),
		"clue_usage": Utils.drama_manager.clue_usage.duplicate(true),
		"total_decision_time": Utils.drama_manager.total_decision_time,
		"decision_count": Utils.drama_manager.decision_count
	}

	inventory_items = []
	for item in Utils.get_inventory().items:
		if item == null:
			inventory_items.append(null)
			continue

		var saved_item := item.duplicate(true)
		saved_item.resource_path = ""
		inventory_items.append(saved_item)

	inventory_item_names = Utils.get_inventory().item_names.duplicate(true)
	
	# Level data save
	curr_room = Utils.last_room
	pos = Utils.get_player_pos()
	timer_remaining = Utils.get_main_timer_remaining()
	

func load_data():
	var state := {
		"ctx": ctx.duplicate(true),
		"characters": characters.duplicate(true),
		"player_model_state": player_model_state.duplicate(true),
		"drama_manager_state": drama_manager_state.duplicate(true),
		"inventory_items": inventory_items.duplicate(true),
		"inventory_item_names": inventory_item_names.duplicate(true),
		"ai_models_on": ai_models_on,
		"curr_room": curr_room,
		"pos": pos,
		"timer_remaining": timer_remaining
	}

	Utils.queue_loaded_state(state)
	Utils.load_level(curr_room)
