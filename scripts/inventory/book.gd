extends Control

@onready var book_animation: AnimatedSprite2D = $AnimatedSprite2D

@onready var inv_ui = $Inventory_UI
@onready var chars_ui = $Characters_UI
@onready var victim_ui = $Victim_UI
@onready var next_page: Button = $Next
@onready var prev_page: Button = $Prev

var is_open
var page: PageType

signal opened
signal closed
signal minigame

enum PageType {INV, CHARS, VICTIM, NONE}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	begin_closed()
	
	next_page.connect("pressed", turn_page_next)
	prev_page.connect("pressed", turn_page_prev)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		if is_open:
			close()
		else:
			open()

func open():
	visible = true
	is_open = true
	opened.emit()
	book_animation.play('open')
	await book_animation.animation_finished
	show_inv()

func close():
	inv_ui.close()
	next_page.visible = false
	chars_ui.visible = false
	prev_page.visible = false
	victim_ui.visible = false
	book_animation.play('close')
	await book_animation.animation_finished
	visible = false
	is_open = false
	closed.emit()
	page = PageType.NONE
	
func begin_closed():
	inv_ui.close()
	next_page.visible = false
	visible = false
	is_open = false
	page = PageType.NONE


func turn_page_next():
	if page == PageType.INV:
		inv_ui.close()
		next_page.visible = false
		book_animation.play('switch_right')
		await book_animation.animation_finished
		show_chars()
		
	elif page == PageType.CHARS:
		chars_ui.visible = false
		next_page.visible = false
		prev_page.visible = false
		book_animation.play('switch_right')
		await book_animation.animation_finished
		show_victim()
		

func turn_page_prev():
	if page == PageType.CHARS:
		chars_ui.visible = false
		prev_page.visible = false
		next_page.visible = false
		book_animation.play('switch_left')
		await book_animation.animation_finished
		show_inv()
		
	elif page == PageType.VICTIM:
		victim_ui.visible = false
		prev_page.visible = false
		book_animation.play('switch_left')
		await book_animation.animation_finished
		show_chars()

func show_inv():
	inv_ui.open()
	next_page.visible = true
	page = PageType.INV

func show_chars():
	chars_ui.visible = true
	prev_page.visible = true
	next_page.visible = true
	page = PageType.CHARS

func show_victim():
	victim_ui.visible = true
	prev_page.visible = true
	page = PageType.VICTIM


func _on_inventory_ui_minigame(minigame_instance: Minigame) -> void:
	minigame.emit(minigame_instance)
