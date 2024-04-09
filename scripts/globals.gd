extends Node

enum GNOME_STATE {IDLE, CLEARING_DEBRIS, PLANTING_SEED, PLANTING_SEED2, TENDING_PLANT, HARVESTING, HAULING}
enum GAME_MODES {STANDARD, SANDBOX}

#color shortcut constants
const CLEAR_HIGHLIGHT_COLOR = Color(0,0,0.5,0.5)
const PLANT_HIGHLIGHT_COLOR = Color(0,0.5,0,0.5)
const REMOVE_COLOR = Color(1,1,1,1)
const HIGHLIGHT_COLOR = Color(1,1,1,0.4)
const REMOVE_HIGHLIGHT_COLOR = Color(1,1,1,0)

var fruit_counter = []

signal purchased

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
