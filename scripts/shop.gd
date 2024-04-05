extends CanvasLayer

@onready var confirmation_buttons = $ConfirmationButtonsContainer
@onready var item_list = $ItemListContainer/ItemList
@onready var bottom_message = $BottomMessageRect/BottomMessage
@onready var top_message = $TopMessageRect/TopMessage

var default_bottom_text = "Cost: "
var default_top_text = [
	"Welcome to my seed shop!",
	"What can I get you today?",
	"The first one's free!"
]


# Called when the node enters the scene tree for the first time.
func _ready():
	bottom_message.set_text(default_bottom_text)
	top_message.set_text(default_top_text[randi_range(0, default_top_text.size()-1)])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_item_list_item_selected(index):
	confirmation_buttons.set_visible(true)
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
	confirmation_buttons.set_visible(false)
	item_list.deselect_all()
	bottom_message.set_text(default_bottom_text)
	top_message.set_text(default_top_text[randi_range(0, default_top_text.size()-1)])
