extends CanvasLayer

@onready var buttons_container = $TopMarginContainer
@onready var plant2_button = $TopMarginContainer/HBoxContainer/PlantCrop2MenuButton

@onready var menu_container = $MenuContainer

@onready var message_container = $MessageContainer
@onready var message_label = $MessageContainer/HBoxContainer/Label
@onready var message_timer = $MessageContainer/Timer
@onready var message_buffer_timer = $MessageContainer/Timer2

@onready var left_side_container = $LeftSideContainer
@onready var flower_counter = $LeftSideContainer/VBoxContainer/HBoxContainer/FlowersCount
@onready var fruit_counters = [
	$LeftSideContainer/VBoxContainer/HBoxContainer2/FruitsCount, 
	$LeftSideContainer/VBoxContainer/HBoxContainer4/FruitsCount
]
@onready var fruit_counter_containers = [
	$LeftSideContainer/VBoxContainer/HBoxContainer2,
	$LeftSideContainer/VBoxContainer/HBoxContainer4
]
@onready var garden_score = $LeftSideContainer/VBoxContainer/HBoxContainer3/GardenScore

@onready var bottom_margin_container = $BottomMarginContainer
@onready var day = $BottomMarginContainer/TimeContainer/Day
@onready var day_timer = $BottomMarginContainer/TimeContainer/DayTimer

@onready var shop_container = $ShopContainer

var message_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func show_game_hud():
	menu_container.set_visible(false)
	buttons_container.set_visible(true)
	bottom_margin_container.set_visible(true)
	left_side_container.set_visible(true)
	day_timer.start()

func show_menu_hud():
	buttons_container.set_visible(false)
	bottom_margin_container.set_visible(false)
	left_side_container.set_visible(false)
	menu_container.set_visible(true)

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

# Hides the message when the timer is up
func _on_timer_timeout():
	message_container.set_visible(false)
	message_buffer_timer.set_wait_time(1.0)
	message_buffer_timer.start()

func update_flower_counter(count):
	flower_counter.set_text(str(count))

func update_fruit_counter(fruits_count_array):
	for i in range(0, fruits_count_array.size()):
		fruit_counters[i].set_text(": " + str(fruits_count_array[i]))

func update_garden_score(score):
	garden_score.set_text(str(score))

func update_plant_button_visibility(fruit_count):
	if fruit_count[0] >= 3:
		plant2_button.set_visible(true)
		fruit_counter_containers[1].set_visible(true)

func show_shop(shopping):
	if shopping:
		shop_container.set_visible(true)
	else:
		shop_container.set_visible(false)
