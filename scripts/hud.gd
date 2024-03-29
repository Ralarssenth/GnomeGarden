extends CanvasLayer

@onready var buttons_container = $ButtonsContainer
@onready var plant2_button = $ButtonsContainer/HBoxContainer/PlantCrop2MenuButton

@onready var menu_container = $MenuContainer
@onready var levels_container = $MenuContainer/MarginContainer/VBoxContainer/LevelsContainer
@onready var save_button = $MenuContainer/MarginContainer/VBoxContainer/SaveGame
@onready var load_button = $MenuContainer/MarginContainer/VBoxContainer/LoadGame
@onready var quit_button = $MenuContainer/MarginContainer/VBoxContainer/QuitToMenu

@onready var message_container = $MessageContainer
@onready var message_label = $MessageContainer/HBoxContainer/Label
@onready var message_timer = $MessageContainer/Timer
@onready var message_buffer_timer = $MessageContainer/Timer2

@onready var score_container = $ScoreContainer
@onready var flower_counter = $ScoreContainer/HBoxContainer/HBoxContainer/FlowersCount
@onready var fruit_counter = $ScoreContainer/HBoxContainer/HBoxContainer2/FruitsCount
@onready var garden_score = $ScoreContainer/HBoxContainer/HBoxContainer3/GardenScore
@onready var day = $ScoreContainer/TimeContainer/Day


var message_list = []
var menu_on = true
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func toggle_hud():
	if menu_on:
		show_game_hud()
	else:
		show_menu_hud()
	menu_on = !menu_on

func show_game_hud():
	menu_container.set_visible(false)
	buttons_container.set_visible(true)
	score_container.set_visible(true)

func show_menu_hud():
	if Globals.in_level:
		menu_container.set_visible(true)
		levels_container.set_visible(false)
		load_button.set_visible(true)
		save_button.set_visible(true)
		quit_button.set_visible(true)
		
	else:
		menu_container.set_visible(true)
		levels_container.set_visible(true)
		buttons_container.set_visible(false)
		score_container.set_visible(false)
		load_button.set_visible(true)
		save_button.set_visible(false)
		quit_button.set_visible(false)

func update_message_list(text):
	message_list.append_array(text)

# updates the message text, displays, and starts the message timer
func show_message_text():
	while not message_list.is_empty():
		message_label.set_text(message_list.pop_front())
		message_container.set_visible(true)
		message_timer.set_wait_time(5.0)
		message_timer.start()
		await message_buffer_timer.timeout

func end_messages_early():
	message_container.set_visible(false)
	message_timer.stop()
	message_buffer_timer.stop()
	message_list.clear()

# Hides the message when the timer is up
func _on_timer_timeout():
	message_container.set_visible(false)
	message_buffer_timer.set_wait_time(1.0)
	message_buffer_timer.start()

func update_flower_counter(count):
	flower_counter.set_text(str(count))

func update_fruit_counter(count):
	fruit_counter.set_text(str(count))

func update_garden_score(score):
	garden_score.set_text(str(score))

func update_plant_button_visibility(fruit_count):
	if fruit_count >= 3:
		plant2_button.set_visible(true)

