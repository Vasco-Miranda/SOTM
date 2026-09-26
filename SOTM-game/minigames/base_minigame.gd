class_name Minigame
extends Control

enum MinigameType {
	MULTI_LEVEL,
	SINGLE_LEVEL
}

enum FinishReason {
	SUCCESS,
	WRONG_ANSWER,
	TIMEOUT
}

@onready var container = $CenterContainer
@onready var timer = $Timer_UI
@onready var rules_container = $Rules
@onready var rules_label = $Rules/Label
@onready var start_label = $Rules/StartLabel

@export var minigame_id: String = ""
@export var clue_id: String = ""
@export var rules: String
@export var type: MinigameType = MinigameType.SINGLE_LEVEL
@export var minigame1_scene: PackedScene
@export var minigame2_scene: PackedScene
@export var minigame3_scene: PackedScene

var waiting_for_start := false
var started_at_ms: int = 0
var current_level_index: int = 0
var metrics := {}
var has_submitted_metrics := false

signal succeeded
signal failed
signal finished

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	show_rules()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func show_rules():
	timer.pause_timer()
	timer.restart_timer()
	
	rules_label.text = rules
	rules_container.visible = true
	rules_container.modulate.a = 0

	var tween = create_tween()
	tween.tween_property(
		rules_container,
		"modulate:a",
		1.0,
		0.5
	)

	await tween.finished

	waiting_for_start = true
	start_label.visible = true
	
	var blink_tween := create_tween()
	blink_tween.set_loops()

	blink_tween.tween_property(
		start_label,
		"modulate:a",
		0.3,
		0.8
	)

	blink_tween.tween_property(
		start_label,
		"modulate:a",
		1.0,
		0.8
	)


func start_game():
	var tween = create_tween()

	tween.tween_property(
		rules_label,
		"modulate:a",
		0.0,
		0.4
	)

	await tween.finished

	rules_container.visible = false

	minigame_start()


func minigame_start():
	container.visible = true
	timer.visible = true
	timer.resume_timer()
	_reset_metrics()
	
	var minigame1 = minigame1_scene.instantiate()
	_prepare_level(minigame1, 0)
	
	if type == MinigameType.MULTI_LEVEL:
		var minigame2 = minigame2_scene.instantiate()
		_prepare_level(minigame2, 1)

		minigame1.right.connect(_on_level_right_next.bind(minigame1, minigame2))
		minigame2.wrong.connect(_on_level_wrong.bind(minigame2))
	
		if minigame3_scene:
			var minigame3 = minigame3_scene.instantiate()
			_prepare_level(minigame3, 2)
			minigame2.right.connect(_on_level_right_next.bind(minigame2, minigame3))
			minigame3.wrong.connect(_on_level_wrong.bind(minigame3))
			minigame3.right.connect(_on_level_right_success.bind(minigame3))
		else:
			minigame2.right.connect(_on_level_right_success.bind(minigame2))
		
	elif type == MinigameType.SINGLE_LEVEL:
		minigame1.right.connect(_on_level_right_success.bind(minigame1))
	
	minigame1.wrong.connect(_on_level_wrong.bind(minigame1))
	
	container.add_child(minigame1)


func next_minigame(prev: Node, next: Node):
	container.remove_child(prev)
	container.add_child(next)


func fail(reason: FinishReason = FinishReason.WRONG_ANSWER):
	_submit_metrics(false, reason)
	failed.emit()
	finished.emit()


func success():
	_submit_metrics(true, FinishReason.SUCCESS)
	succeeded.emit()
	finished.emit()


func _on_timer_ui_timed_out() -> void:
	fail(FinishReason.TIMEOUT)


func configure_for_item(item: InvItem) -> void:
	if item == null:
		return


	clue_id = item.get_clue_id()
	if minigame_id == "":
		minigame_id = clue_id


func _reset_metrics() -> void:
	started_at_ms = Time.get_ticks_msec()
	current_level_index = 0
	has_submitted_metrics = false
	metrics = {
		"minigame_id": minigame_id,
		"clue_id": clue_id,
		"minigame_type": MinigameType.keys()[type],
		"time_limit": timer.time,
		"time_left": timer.timer.time_left,
		"duration": 0.0,
		"levels_total": _get_level_count(),
		"levels_completed": 0,
		"attempts": 0,
		"correct_attempts": 0,
		"wrong_attempts": 0,
		"inputs": 0,
		"current_error_streak": 0,
		"max_error_streak": 0,
		"success": false,
		"timed_out": false,
		"finish_reason": "",
		"events": []
	}


func _prepare_level(level: Node, index: int) -> void:
	if level is MinigameLevel:
		level.begin_metrics(index)
		level.metric_recorded.connect(_on_level_metric_recorded)


func _on_level_right_next(level: Node, next: Node) -> void:
	_record_completed_level(level)
	next_minigame(level, next)


func _on_level_right_success(level: Node) -> void:
	_record_completed_level(level)
	success()


func _on_level_wrong(_level: Node) -> void:
	fail(FinishReason.WRONG_ANSWER)


func _record_completed_level(level: Node) -> void:
	var completed_index := current_level_index
	if level is MinigameLevel:
		completed_index = level.level_index
	
	metrics["levels_completed"] = max(metrics["levels_completed"], completed_index + 1)
	current_level_index = completed_index + 1


func _on_level_metric_recorded(event: Dictionary) -> void:
	metrics["events"].append(event.duplicate(true))

	match str(event.get("name", "")):
		"input":
			metrics["inputs"] += 1
		"attempt":
			metrics["attempts"] += 1
			metrics["inputs"] += 1
			if event["is_correct"]:
				metrics["correct_attempts"] += 1
				metrics["current_error_streak"] = 0
			else:
				metrics["wrong_attempts"] += 1
				metrics["current_error_streak"] += 1
				metrics["max_error_streak"] = max(metrics["max_error_streak"], metrics["current_error_streak"])


func _submit_metrics(was_successful: bool, reason: int) -> void:
	if has_submitted_metrics:
		return

	has_submitted_metrics = true
	timer.pause_timer()
	metrics["success"] = was_successful
	metrics["timed_out"] = reason == FinishReason.TIMEOUT
	metrics["finish_reason"] = FinishReason.keys()[reason]
	metrics["duration"] = maxf(0.0, float(Time.get_ticks_msec() - started_at_ms) / 1000.0)
	metrics["time_left"] = timer.timer.time_left
	Utils.register_minigame_result(metrics)


func _get_level_count() -> int:
	if type == MinigameType.SINGLE_LEVEL:
		return 1
	
	var count := 1
	if minigame2_scene:
		count += 1
	if minigame3_scene:
		count += 1
	return count


func _on_gui_input(event: InputEvent) -> void:
	if waiting_for_start and event is InputEventMouseButton and event.pressed:
		waiting_for_start = false
		start_game()
