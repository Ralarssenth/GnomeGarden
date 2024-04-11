extends CanvasLayer

@onready var confirmation_buttons = $ConfirmationButtonsContainer
@onready var item_list = $ItemListContainer/ItemList
@onready var bottom_message = $BottomMessageRect/BottomMessage
@onready var top_message = $TopMessageRect/TopMessage
@onready var close_button = $CloseXButton
@onready var back_button = $BackButton
@onready var button_audiostream = $ButtonClick

var click_sound = preload("res://assets/music and sounds/zipclick.wav")
var successful_buy_sound = preload("res://assets/music and sounds/snd_purchase.wav")
var failed_buy_sound = preload("res://assets/music and sounds/Menu Selection Click.wav")

var default_bottom_text = "Cost: "
var default_top_text = [
	"Welcome to my seed shop!",
	"What can I get you today?",
	"The first one's free!"
]
var failed_buy_message = [
	"Looks like you can't afford it.",
	"Sorry, no discounts."
]
var succeeded_buy_message = [
	"Good choice!",
	"Anything else I can get for you?"
]


# Called when the node enters the scene tree for the first time.
func _ready():
	set_default_values()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_default_values():
	bottom_message.set_text(default_bottom_text)
	top_message.set_text(default_top_text[randi_range(0, default_top_text.size()-1)])
	item_list.deselect_all()

func _on_item_list_item_selected(index):
	button_audiostream.set_stream(click_sound)
	button_audiostream.play()
	var item_selected = true
	toggle_bottom_buttons(item_selected)
	top_message.set_text("Don't ask where I got these seeds from...")
	match index:
		0:
			bottom_message.set_text("Cost: Free!")
		1:
			bottom_message.set_text("Cost: 3 Tomatoes")
		_:
			bottom_message.set_text(default_bottom_text)
			top_message.set_text(default_top_text[randi_range(0, default_top_text.size()-1)])
			

func _on_no_button_pressed():
	button_audiostream.set_stream(click_sound)
	button_audiostream.play()
	var item_selected = false
	toggle_bottom_buttons(item_selected)
	item_list.deselect_all()
	bottom_message.set_text(default_bottom_text)
	top_message.set_text(default_top_text[randi_range(0, default_top_text.size()-1)])


func _on_yes_button_pressed():
	var selected_items = item_list.get_selected_items()
	var item_index = selected_items[0]
	
	Globals.purchased.emit(item_index)

func failed_to_buy():
	button_audiostream.set_stream(failed_buy_sound)
	button_audiostream.play()
	top_message.set_text(failed_buy_message[randi_range(0, failed_buy_message.size()-1)])
	
func succeeded_buy():
	button_audiostream.set_stream(successful_buy_sound)
	button_audiostream.play()
	# Disable the selected item in the item list
	var selected_items = item_list.get_selected_items()
	var item_index = selected_items[0]
	item_list.set_item_disabled(item_index, true)
	# Swap the bottom buttons back
	var item_selected = false
	toggle_bottom_buttons(item_selected)
	top_message.set_text(succeeded_buy_message[randi_range(0, succeeded_buy_message.size()-1)])

func toggle_bottom_buttons(item_selected):
	confirmation_buttons.set_visible(item_selected)
	back_button.set_visible(not item_selected)


