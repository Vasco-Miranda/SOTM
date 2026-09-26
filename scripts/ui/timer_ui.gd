extends Control

signal timed_out

@onready var timer = $Timer
@onready var label = $NinePatchRect/Label

@export var time: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.wait_time = time
	timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Get the total time left in seconds
	var time_left: float = timer.time_left
	
	# Calculate minutes and seconds
	var minutes: int = int(time_left) / 60
	var seconds: int = int(time_left) % 60
	
	# Format the numbers to always have two digits
	label.text = "%02d:%02d" % [minutes, seconds]

func pause_timer():
	timer.paused = true

func resume_timer():
	timer.paused = false

func restart_timer():
	timer.wait_time = time

func get_time_left() -> float:
	return timer.time_left

func set_time_left(time_left: float) -> void:
	timer.start(clampf(time_left, 0.0, time))


func _on_timer_timeout() -> void:
	timed_out.emit()
