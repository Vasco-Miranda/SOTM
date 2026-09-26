extends MinigameLevel

@onready var grid = $NinePatchRect/MarginContainer/GridContainer

@export var rows := 5
@export var columns := 10

@export var cell_scene: PackedScene

@export var arrow_up: Texture2D
@export var arrow_down: Texture2D
@export var arrow_left: Texture2D
@export var arrow_right: Texture2D

@export var hidden_texture: Texture2D

var cells = []
var direction_arrows = {}
var goal_x
var goal_y

# Called when the node enters the scene tree for the first time.
func _ready():
	create_grid()
	pick_goal()
	
	direction_arrows = {
		"up": arrow_up,
		"down": arrow_down,
		"left": arrow_left,
		"right": arrow_right
	}


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func create_grid():
	grid.columns = columns
	for y in range(rows):
		var row = []
		for x in range(columns):
			var cell = cell_scene.instantiate()
			grid.add_child(cell)
			cell.selected.connect(_on_cell_selected.bind(x, y))
			row.append(cell)
		cells.append(row)


func pick_goal():
	randomize()
	goal_x = randi() % columns
	goal_y = randi() % rows


func _on_cell_selected(x:int, y:int):
	if x == goal_x and y == goal_y:
		record_attempt(true, "search_cell")
		win(x, y)
		return
	record_attempt(false, "search_cell")
	show_hint(x, y)


func show_hint(x:int, y:int):
	var directions = []
	var cell = cells[y][x]
	await get_tree().create_timer(0.3).timeout
	if goal_y < y:
		directions.append("up")
	elif goal_y > y:
		directions.append("down")
	elif goal_x < x:
		directions.append("left")
	elif goal_x > x:
		directions.append("right")
	
	var chosen = directions.pick_random()
	cell.show_arrow(direction_arrows[chosen])


func win(x:int, y:int):
	var cell = cells[y][x]
	cell.reveal(hidden_texture)
	await get_tree().create_timer(1.0).timeout
	right.emit()
