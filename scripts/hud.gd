extends CanvasLayer

@onready var message_container = $MessageContainer
@onready var message_label = $MessageContainer/HBoxContainer/Label
@onready var message_timer = $MessageContainer/Timer
@onready var message_buffer_timer = $MessageContainer/Timer2
@onready var flower_counter = $ScoreContainer/HBoxContainer/HBoxContainer/FlowersCount
@onready var fruit_counter = $ScoreContainer/HBoxContainer/HBoxContainer2/FruitsCount
@onready var garden_score = $ScoreContainer/HBoxContainer/HBoxContainer3/GardenScore

var message_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_message_list(text):
	message_list.push_back(text)

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

func update_fruit_counter(count):
	fruit_counter.set_text(str(count))

func update_garden_score(score):
	garden_score.set_text(str(score))
