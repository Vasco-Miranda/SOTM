class_name MinigameLevel
extends Control

signal wrong
signal right
signal metric_recorded(event: Dictionary)

var level_index: int = 0
var level_started_at_ms: int = 0

func begin_metrics(index: int) -> void:
	level_index = index
	level_started_at_ms = Time.get_ticks_msec()

func record_input(action: String = "") -> void:
	emit_metric({
		"name": "input",
		"action": action
	})

func record_attempt(is_correct: bool, action: String = "") -> void:
	emit_metric({
		"name": "attempt",
		"is_correct": is_correct,
		"action": action
	})


func emit_metric(event: Dictionary) -> void:
	event["level_index"] = level_index
	event["elapsed"] = get_elapsed_seconds()
	metric_recorded.emit(event)

func get_elapsed_seconds() -> float:
	if level_started_at_ms <= 0:
		return 0.0

	return maxf(0.0, float(Time.get_ticks_msec() - level_started_at_ms) / 1000.0)
