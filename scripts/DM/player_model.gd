class_name PlayerModel extends Resource

var PLAYER_INV = preload("res://inventory/player_inv.tres")
const RAPID_DIALOGUE_THRESHOLD := 0.55
const RAPID_ROOM_CHANGE_THRESHOLD := 8.0

var emotional_state := {
	"stress": 0.0,
	"confusion": 0.0,
	"self_doubt": 0.0
}

var stress_markers := {
	"rapid_dialogue_clicks": 0.0,
	"rapid_room_changes": 0.0,
	"minigame_pressure": 0.0
}

var stress_runtime := {
	"rapid_dialogue_streak": 0,
	"rapid_room_change_streak": 0,
	"last_room_change_ms": 0
}

var social_state := {
	"affinity": {}, # character_name : float
	"blame": {}     # character_name : float
}

var cognitive_state := {
	"clue_weight": {}, # clue_id : float
	"minigame_evidence_focus": 0.0,
	"minigame_pressure_focus": 0.0
}

var minigame_evaluations: Array[Dictionary] = []

### PLAYER STATE HANDLERS

func init(characters: Array, clues: Array):
	emotional_state = {
		"stress": 0.0,
		"confusion": 0.0,
		"self_doubt": 0.0
	}

	stress_markers = {
		"rapid_dialogue_clicks": 0.0,
		"rapid_room_changes": 0.0,
		"minigame_pressure": 0.0
	}

	stress_runtime = {
		"rapid_dialogue_streak": 0,
		"rapid_room_change_streak": 0,
		"last_room_change_ms": 0
	}

	social_state = {
		"affinity": {},
		"blame": {}
	}

	cognitive_state = {
		"clue_weight": {},
		"minigame_evidence_focus": 0.0,
		"minigame_pressure_focus": 0.0
	}

	minigame_evaluations = []

	for c in characters:
		social_state["affinity"][c] = 0.0
		social_state["blame"][c] = 0.0

	for clue in clues:
		cognitive_state["clue_weight"][clue] = 0.0

func clamp_values():
	emotional_state["stress"] = clamp(emotional_state["stress"], -10, 10)
	emotional_state["confusion"] = clamp(emotional_state["confusion"], -10, 10)
	emotional_state["self_doubt"] = clamp(emotional_state["self_doubt"], -10, 10)

func apply_choice(choice: Choice, actual_time_taken: float) -> void:
	_apply_emotional_deltas(choice, actual_time_taken)
	_apply_social_deltas(choice)
	_apply_cognitive_deltas(choice)
	_apply_choice_tags(choice.tags, choice.character)
	clamp_values()

func get_player_profile():
	return {
		"is_stressed": emotional_state["stress"] > 7,
		"is_confused": emotional_state["confusion"] > 6,
		"is_decisive": emotional_state["self_doubt"] < -3,
		"is_paranoid": emotional_state["self_doubt"] > 5,
		"stress": emotional_state["stress"],
		"confusion": emotional_state["confusion"],
		"self_doubt": emotional_state["self_doubt"]
	}

func get_latest_minigame_evaluation() -> Dictionary:
	if minigame_evaluations.is_empty():
		return {}

	return minigame_evaluations[-1].duplicate(true)

func add_pattern_effects(confusion_delta: float, self_doubt_delta: float, stress_delta: float) -> void:
	emotional_state["confusion"] += confusion_delta
	emotional_state["self_doubt"] += self_doubt_delta
	emotional_state["stress"] += stress_delta
	clamp_values()

func register_dialogue_pacing(actual_time_taken: float) -> void:
	if actual_time_taken <= 0.0:
		return

	if actual_time_taken <= RAPID_DIALOGUE_THRESHOLD:
		stress_runtime["rapid_dialogue_streak"] += 1

		var streak = stress_runtime["rapid_dialogue_streak"]
		if streak >= 2:
			stress_markers["rapid_dialogue_clicks"] += 0.5
			emotional_state["stress"] += 0.05 + (min(streak, 4) - 2) * 0.05
		if streak >= 3:
			emotional_state["confusion"] += 0.08
	else:
		stress_runtime["rapid_dialogue_streak"] = 0

	clamp_values()

func register_room_change(now_ms: int) -> void:
	var last_room_change_ms := int(stress_runtime.get("last_room_change_ms", 0))
	if last_room_change_ms > 0:
		var elapsed := maxf(0.0, float(now_ms - last_room_change_ms) / 1000.0)
		if elapsed <= RAPID_ROOM_CHANGE_THRESHOLD:
			stress_runtime["rapid_room_change_streak"] += 1

			var streak = stress_runtime["rapid_room_change_streak"]
			if streak >= 2:
				stress_markers["rapid_room_changes"] += 1.0
				emotional_state["stress"] += 0.05 + (min(streak, 4) - 2) * 0.05
				emotional_state["confusion"] += 0.12
		else:
			stress_runtime["rapid_room_change_streak"] = 0

	stress_runtime["last_room_change_ms"] = now_ms
	clamp_values()

func register_minigame_stress(marker_id: String, stress_delta: float, confusion_delta: float = 0.0, self_doubt_delta: float = 0.0, marker_weight: float = 1.0) -> void:
	stress_markers["minigame_pressure"] += maxf(0.0, marker_weight)
	if marker_id != "":
		stress_markers[marker_id] = stress_markers.get(marker_id, 0.0) + maxf(0.0, marker_weight)

	emotional_state["stress"] += stress_delta
	emotional_state["confusion"] += confusion_delta
	emotional_state["self_doubt"] += self_doubt_delta
	clamp_values()

func register_minigame_result(metrics: Dictionary) -> Dictionary:
	var evaluation := _evaluate_minigame(metrics)
	minigame_evaluations.append(evaluation)

	var marker_weight: float = evaluation["pressure_score"]
	stress_markers["minigame_pressure"] += marker_weight
	stress_markers["minigame_errors"] = stress_markers.get("minigame_errors", 0.0) + float(metrics.get("wrong_attempts", 0))
	if bool(metrics.get("timed_out", false)):
		stress_markers["minigame_timeouts"] = stress_markers.get("minigame_timeouts", 0.0) + 1.0

	emotional_state["stress"] += evaluation["stress_delta"]
	emotional_state["confusion"] += evaluation["confusion_delta"]
	emotional_state["self_doubt"] += evaluation["self_doubt_delta"]

	var clue_id := str(metrics.get("clue_id", ""))
	if clue_id != "":
		cognitive_state["clue_weight"][clue_id] = cognitive_state["clue_weight"].get(clue_id, 0.0) + evaluation["clue_focus_delta"]

	cognitive_state["minigame_evidence_focus"] = cognitive_state.get("minigame_evidence_focus", 0.0) + evaluation["evidence_focus_delta"]
	cognitive_state["minigame_pressure_focus"] = cognitive_state.get("minigame_pressure_focus", 0.0) + evaluation["pressure_focus_delta"]

	clamp_values()
	return evaluation

func _evaluate_minigame(metrics: Dictionary) -> Dictionary:
	var attempts = max(1, int(metrics.get("attempts", 0)))
	var wrong_attempts := int(metrics.get("wrong_attempts", 0))
	var levels_total = max(1, int(metrics.get("levels_total", 1)))
	var levels_completed := int(metrics.get("levels_completed", 0))
	var success := bool(metrics.get("success", false))
	var timed_out := bool(metrics.get("timed_out", false))
	var max_error_streak := int(metrics.get("max_error_streak", 0))
	var time_limit := maxf(0.1, float(metrics.get("time_limit", 1.0)))
	var time_left := maxf(0.0, float(metrics.get("time_left", 0.0)))

	var accuracy := clampf(float(attempts - wrong_attempts) / float(attempts), 0.0, 1.0)
	var completion := clampf(float(levels_completed) / float(levels_total), 0.0, 1.0)
	var time_left_ratio := clampf(time_left / time_limit, 0.0, 1.0)

	var performance_score := (
		accuracy * 0.45
		+ completion * 0.35
		+ time_left_ratio * 0.20
	)
	if success:
		performance_score = minf(1.0, performance_score + 0.15)
	if timed_out:
		performance_score = maxf(0.0, performance_score - 0.25)

	var pressure_score := 0.0
	pressure_score += float(wrong_attempts) * 0.5
	pressure_score += float(max_error_streak) * 0.2
	if time_left_ratio <= 0.2:
		pressure_score += 0.75
	if timed_out:
		pressure_score += 1.5
	if not success:
		pressure_score += 0.8
	pressure_score = clampf(pressure_score, 0.0, 5.0)

	var stress_delta := pressure_score * 0.25
	var confusion_delta := float(wrong_attempts) * 0.15 + float(max_error_streak) * 0.1
	var self_doubt_delta := 0.0
	var clue_focus_delta := 0.0
	var evidence_focus_delta := 0.0
	var pressure_focus_delta := pressure_score * 0.25

	if success:
		stress_delta -= 0.25 * performance_score
		self_doubt_delta -= 0.35 * performance_score
		clue_focus_delta += 0.5 + performance_score
		evidence_focus_delta += 0.75 + performance_score
		if pressure_score <= 1.0:
			pressure_focus_delta *= 0.5
	else:
		stress_delta += 0.1
		self_doubt_delta += 0.45 + (1.0 - performance_score) * 0.35
		confusion_delta += 0.25
		clue_focus_delta += completion * 0.35
		evidence_focus_delta += completion * 0.5
		pressure_focus_delta += 0.75

	if timed_out:
		confusion_delta += 0.25
		self_doubt_delta += 0.25
		pressure_focus_delta += 0.75

	return {
		"metrics": metrics.duplicate(true),
		"performance_score": performance_score,
		"pressure_score": pressure_score,
		"stress_delta": stress_delta,
		"confusion_delta": confusion_delta,
		"self_doubt_delta": self_doubt_delta,
		"clue_focus_delta": clue_focus_delta,
		"evidence_focus_delta": evidence_focus_delta,
		"pressure_focus_delta": pressure_focus_delta
	}

func _apply_emotional_deltas(choice: Choice, actual_time_taken: float) -> void:
	emotional_state["stress"] += choice.stress_delta
	emotional_state["confusion"] += choice.confusion_delta
	emotional_state["self_doubt"] += choice.self_doubt_delta

	var hesitation := maxf(0.0, actual_time_taken - choice.expected_time)
	emotional_state["stress"] += hesitation * choice.hesitation_weight
	emotional_state["self_doubt"] += hesitation * 0.3

func _apply_social_deltas(choice: Choice) -> void:
	if choice.character == "":
		return

	social_state["affinity"][choice.character] += choice.affinity_delta
	social_state["blame"][choice.character] += choice.blame_delta

func _apply_cognitive_deltas(choice: Choice) -> void:
	if choice.clue == "":
		return

	cognitive_state["clue_weight"][choice.clue] += choice.clue_focus

func _apply_choice_tags(tags: Array[String], character_name: String) -> void:
	for tag in tags:
		match tag:
			"accusation":
				emotional_state["stress"] += 0.1
				emotional_state["self_doubt"] -= 0.3
			"empathetic":
				emotional_state["stress"] -= 0.4
				_change_affinity(character_name, 0.5)
			"deflect":
				emotional_state["confusion"] += 0.3
				emotional_state["self_doubt"] += 0.1
			"self_incriminate":
				emotional_state["confusion"] += 0.35
				emotional_state["self_doubt"] += 1.0
			"flirt":
				emotional_state["stress"] -= 0.25
				_change_affinity(character_name, 0.2)
			"pressure":
				emotional_state["stress"] += 0.1
				emotional_state["self_doubt"] -= 0.2
			"reassure":
				emotional_state["stress"] -= 0.5
				emotional_state["self_doubt"] -= 0.2
			"probe":
				emotional_state["confusion"] -= 0.1
			"family":
				emotional_state["self_doubt"] += 0.2
			"evidence":
				emotional_state["confusion"] -= 0.15

func _change_affinity(character_name: String, delta: float) -> void:
	if character_name == "":
		return

	social_state["affinity"][character_name] += delta

func has_clue(clue: String) -> bool:
	if PLAYER_INV == null:
		return false

	return PLAYER_INV.has_clue(clue)

func has_revealed_clue(clue: String) -> bool:
	if PLAYER_INV == null:
		return false

	return PLAYER_INV.has_revealed_clue(clue)
