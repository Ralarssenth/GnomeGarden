extends CanvasLayer

@onready var buttons_container = $TopMarginContainer
@onready var menu_button = $TopMarginContainer/HBoxContainer/MenuButton
@onready var shop_button = $TopMarginContainer/HBoxContainer/ShopButton
@onready var plant_buttons = [
	$TopMarginContainer/HBoxContainer/PlantCropMenuButton,
	$TopMarginContainer/HBoxContainer/PlantCrop2MenuButton
]
@onready var pause_button = $TopMarginContainer/HBoxContainer2/PauseButton

@onready var menu_container = $MenuContainer
@onready var level_select_menu = [
	$MenuContainer/MarginContainer/VBoxContainer/LevelSelect,
	$MenuContainer/MarginContainer/VBoxContainer/SandboxLevel,
	$MenuContainer/MarginContainer/VBoxContainer/TutorialLevel
]
@onready var options_menu = $OptionsMenu
@onready var menu_back_button = $MenuContainer/MarginContainer/VBoxContainer/BackButton

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

@onready var shop = $Shop

@onready var button_click_sound = $ButtonClick

var message_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	register_buttons()
	show_menu_hud()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func register_buttons():
	var close_shop_buttons = get_tree().get_nodes_in_group("close_shop_buttons")
	for button in close_shop_buttons:
		var callable = Callable(self, "_close_shop")
		button.connect("pressed", callable)


func show_game_hud():
	menu_container.set_visible(false)
	buttons_container.set_visible(true)
	bottom_margin_container.set_visible(true)
	left_side_container.set_visible(true)

func show_menu_hud():
	buttons_container.set_visible(false)
	bottom_margin_container.set_visible(false)
	left_side_container.set_visible(false)
	menu_container.set_visible(true)
	menu_back_button.set_visible(false)
	

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

func update_fruit_counter():
	for i in range(0, Globals.fruit_counter.size()-1):
		fruit_counters[i].set_text(": " + str(Globals.fruit_counter[i]))

func update_garden_score(score):
	garden_score.set_text(str(score))

func update_plant_button_visibility(fruit_id):
	plant_buttons[fruit_id].set_visible(true)
	fruit_counter_containers[fruit_id].set_visible(true)

func show_shop(shopping):
	shop.set_visible(shopping)
	if shopping:
		shop.set_default_values()

func _close_shop():
	shop_button.set_pressed(false)

func play_button_click():
	button_click_sound.play()

func toggle_inGame_menu(menu_open):
	menu_back_button.set_visible(true)
	menu_container.set_visible(menu_open)
	for member in level_select_menu:
		member.set_visible(false)
		
	var buttons = get_tree().get_nodes_in_group("toggle_buttons")
	for button in buttons:
		button.set_disabled(menu_open)

func pause_game():
	pause_button.set_pressed(true)

func toggle_options_menu(menu_open):
	options_menu.set_visible(menu_open)
	menu_container.set_visible(not menu_open)
	


func _on_menu_back_button_pressed():
	toggle_inGame_menu(false)
	menu_button.set_pressed(false)


func _on_options_back_button_pressed():
	play_button_click()
	toggle_options_menu(false)
	if Globals.in_level:
		toggle_inGame_menu(true)
	else:
		show_menu_hud()
