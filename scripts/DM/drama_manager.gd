class_name DramaManager
extends Resource

var history: Array = []

# Core systems
var player_model: PlayerModel

# Pattern counters
var tag_counts := {}
var character_interactions := {}
var character_accusations := {}
var clue_usage := {}

# Time tracking
var total_decision_time: float = 0.0
var decision_count: int = 0

func init(characters: Array, clues: Array):
	history.clear()
	tag_counts.clear()
	character_interactions.clear()
	character_accusations.clear()
	clue_usage.clear()
	total_decision_time = 0.0
	decision_count = 0

	player_model = PlayerModel.new()
	player_model.init(characters, clues)


func get_default_ctx():
	return {
		"is_aggressive": false,
		"is_stressed": false,
		"is_confused": false,
		"is_manipulative": false,
		"is_self_incriminating": false,
		"is_roleplaying": false,
		"is_supportive": false,
		"is_suspicious": false,
		"is_favorite": false,
		"is_pressured": false,
		"should_refuse_dialogue": false,
		"affinity": 0,
		"blame": 0,
		"pressure_focus": 0,
		"comfort_focus": 0,
		"family_focus": 0,
		"evidence_focus": 0,
		"self_doubt": 0
	}

func register_choice(choice: Choice, time_taken: float):
	history.append({
		"choice_id": choice.id,
		"character": choice.character,
		"clue": choice.clue,
		"time": time_taken,
		"tags": choice.tags
	})

	decision_count += 1
	total_decision_time += time_taken

	for tag in choice.tags:
		tag_counts[tag] = tag_counts.get(tag, 0) + 1

	if choice.character != "":
		character_interactions[choice.character] = character_interactions.get(choice.character, 0) + 1

		if "accusation" in choice.tags:
			character_accusations[choice.character] = character_accusations.get(choice.character, 0) + 1

	if choice.clue != "":
		clue_usage[choice.clue] = clue_usage.get(choice.clue, 0) + 1

func process_choice(choice: Choice, time_taken: float):
	register_choice(choice, time_taken)
	player_model.apply_choice(choice, time_taken)
	_apply_behavior_effects()
	player_model.clamp_values()

func get_average_decision_time() -> float:
	if decision_count == 0:
		return 0.0
	return total_decision_time / decision_count

func get_tag_count(tag: String) -> int:
	return tag_counts.get(tag, 0)

func get_behavior_profile() -> Dictionary:
	var self_read := get_self_read_profile()

	return {
		"is_accusatory": get_tag_count("accusation") > 5,
		"is_empathetic": get_tag_count("empathetic") > 5,
		"is_avoidant": get_tag_count("deflect") > 5,
		"is_decisive": get_average_decision_time() < 2.0,
		"is_hesitant": get_average_decision_time() > 4.0,
		"is_manipulative": get_tag_count("deflect") > 4,
		"is_flirtatious": self_read["is_flirtatious"],
		"is_self_incriminating": self_read["is_self_incriminating"]
	}

func get_focus_profile() -> Dictionary:
	var minigame_evidence_focus := 0.0
	var minigame_pressure_focus := 0.0
	if player_model != null:
		minigame_evidence_focus = float(player_model.cognitive_state.get("minigame_evidence_focus", 0.0))
		minigame_pressure_focus = float(player_model.cognitive_state.get("minigame_pressure_focus", 0.0))

	return {
		"pressure_focus": get_tag_count("pressure") + minigame_pressure_focus,
		"comfort_focus": get_tag_count("reassure") + get_tag_count("empathetic"),
		"family_focus": get_tag_count("family"),
		"evidence_focus": get_tag_count("evidence") + get_tag_count("probe") + minigame_evidence_focus
	}

func get_self_read_profile() -> Dictionary:
	var flirt_count := get_tag_count("flirt")
	var self_incriminate_count := get_tag_count("self_incriminate")
	var focus := get_focus_profile()

	return {
		"flirt_count": flirt_count,
		"self_incriminate_count": self_incriminate_count,
		"is_flirtatious": flirt_count >= 2,
		"is_self_incriminating": self_incriminate_count >= 4,
		"is_roleplaying": self_incriminate_count >= 2 and focus["evidence_focus"] >= 3
	}

func get_most_suspected() -> String:
	var max_val := -INF
	var suspect := ""

	for char in character_accusations.keys():
		var val = character_accusations[char]
		if val > max_val:
			max_val = val
			suspect = char

	return suspect

func get_most_interacted() -> String:
	var max_val := -INF
	var target := ""

	for char in character_interactions.keys():
		var val = character_interactions[char]
		if val > max_val:
			max_val = val
			target = char

	return target

func get_most_used_clue() -> String:
	var max_val := -INF
	var result := ""

	for clue in clue_usage.keys():
		var val = clue_usage[clue]
		if val > max_val:
			max_val = val
			result = clue

	return result

func is_repeating_behavior() -> bool:
	if history.size() < 5:
		return false

	var recent_history: Array = history.slice(history.size() - 5, history.size())
	var last_entry: Dictionary = recent_history[-1]
	var last_character: String = last_entry["character"]
	var last_clue: String = last_entry["clue"]
	var last_pattern: String = _get_behavior_pattern_key(last_entry)
	var repeated_character_count := 0
	var repeated_clue_count := 0
	var repeated_pattern_count := 0

	for entry in recent_history:
		if last_character != "" and entry["character"] == last_character:
			repeated_character_count += 1

		if last_clue != "" and entry["clue"] == last_clue:
			repeated_clue_count += 1

		if _get_behavior_pattern_key(entry) == last_pattern:
			repeated_pattern_count += 1

	return repeated_character_count >= 4 or repeated_clue_count >= 4 or repeated_pattern_count >= 4

func _get_behavior_pattern_key(entry: Dictionary) -> String:
	var tags: Array = entry["tags"]

	if "accusation" in tags or "pressure" in tags:
		return "pressure"
	if "empathetic" in tags or "reassure" in tags:
		return "comfort"
	if "evidence" in tags or "probe" in tags:
		return "evidence"
	if "family" in tags:
		return "family"
	if "deflect" in tags:
		return "deflect"
	if "flirt" in tags:
		return "flirt"
	if "self_incriminate" in tags:
		return "self_incriminate"

	return "neutral"

func is_contradicting_self() -> bool:
	return get_tag_count("accusation") > 3 and get_tag_count("empathetic") > 3

func _apply_behavior_effects():
	var confusion_delta := 0.0
	var self_doubt_delta := 0.0
	var stress_delta := 0.0

	if is_repeating_behavior():
		confusion_delta += 0.7

	if is_contradicting_self():
		self_doubt_delta += 0.6

	if get_tag_count("accusation") > 6:
		stress_delta += 0.1

	var suspect := get_most_suspected()
	if suspect != "":
		player_model.social_state["blame"][suspect] += 0.2

	player_model.add_pattern_effects(confusion_delta, self_doubt_delta, stress_delta)

func get_character_state(character: String) -> Dictionary:
	var affinity := get_affinity(character)
	var blame := get_blame(character)
	var interactions = character_interactions.get(character, 0)
	var accusations = character_accusations.get(character, 0)
	var behavior := get_behavior_profile()
	var focus := get_focus_profile()
	var is_supportive := affinity - blame >= 2.5
	var is_suspicious := blame - affinity >= 2.5
	var is_pressured = accusations > 0 and get_most_suspected() == character
	var should_refuse_dialogue = (
		accusations >= 3
		and blame >= 4.0
		and affinity <= -2.0
		and is_suspicious
		and behavior["is_accusatory"]
	)

	return {
		"affinity": affinity,
		"blame": blame,
		"interactions": interactions,
		"accusations": accusations,
		"is_favorite": interactions > 0 and get_most_interacted() == character,
		"is_pressured": is_pressured,
		"is_supportive": is_supportive,
		"is_suspicious": is_suspicious,
		"should_refuse_dialogue": should_refuse_dialogue
	}

func get_player_state() -> Dictionary:
	return {
		"behavior": get_behavior_profile(),
		"emotion": player_model.get_player_profile(),
		"self_read": get_self_read_profile(),
		"focus": get_focus_profile(),
		"most_suspected": get_most_suspected(),
		"most_used_clue": get_most_used_clue(),
		"is_repeating": is_repeating_behavior(),
		"is_contradicting": is_contradicting_self()
	}

func get_dialogue_context(character_name: String) -> Dictionary:
	var state := get_player_state()
	var behavior = state["behavior"]
	var emotion = state["emotion"]
	var self_read = state["self_read"]
	var focus = state["focus"]
	var character_state := get_character_state(character_name)

	return {
		"is_aggressive": behavior["is_accusatory"],
		"is_stressed": emotion["is_stressed"],
		"is_confused": emotion["is_confused"],
		"is_manipulative": behavior["is_manipulative"],
		"is_self_incriminating": behavior["is_self_incriminating"],
		"is_roleplaying": self_read["is_roleplaying"],
		"is_supportive": character_state["is_supportive"],
		"is_suspicious": character_state["is_suspicious"],
		"is_favorite": character_state["is_favorite"],
		"is_pressured": character_state["is_pressured"],
		"should_refuse_dialogue": character_state["should_refuse_dialogue"],
		"affinity": character_state["affinity"],
		"blame": character_state["blame"],
		"pressure_focus": focus["pressure_focus"],
		"comfort_focus": focus["comfort_focus"],
		"family_focus": focus["family_focus"],
		"evidence_focus": focus["evidence_focus"],
		"self_doubt": emotion["self_doubt"]
	}

func sync_character_feelings(target_character, character_name: String) -> void:
	if target_character == null or character_name == "":
		return

	var state := get_player_state()
	var character_state := get_character_state(character_name)

	if character_state["is_supportive"]:
		if target_character.feelings["trust"] < 6:
			target_character.increase_trust()
		if target_character.feelings["apprehension"] > 0:
			target_character.decrease_apprehension()
	elif character_state["is_suspicious"]:
		if target_character.feelings["trust"] > -6:
			target_character.decrease_trust()
		if target_character.feelings["apprehension"] < 7:
			target_character.increase_apprehension()

	if character_state["is_favorite"] and target_character.feelings["interest"] < 7:
		target_character.increase_interest()

	if character_state["is_pressured"] and target_character.feelings["apprehension"] < 8:
		target_character.increase_apprehension()

	if state["emotion"]["is_confused"] and character_state["affinity"] >= character_state["blame"] and target_character.feelings["trust"] < 7:
		target_character.increase_trust()

	if state["emotion"]["is_stressed"] and character_state["affinity"] >= character_state["blame"] and target_character.feelings["interest"] < 7:
		target_character.increase_interest()

	if state["emotion"]["is_paranoid"] and character_state["blame"] >= character_state["affinity"] and target_character.feelings["apprehension"] < 8:
		target_character.increase_apprehension()

	if state["self_read"]["is_flirtatious"] and character_state["affinity"] >= 0.0 and target_character.feelings["interest"] < 8:
		target_character.increase_interest()

func get_affinity(character: String) -> float:
	return player_model.social_state["affinity"].get(character, 0.0)

func get_blame(character: String) -> float:
	return player_model.social_state["blame"].get(character, 0.0)

func get_clue_weight(clue: String) -> float:
	return player_model.cognitive_state["clue_weight"].get(clue, 0.0)
