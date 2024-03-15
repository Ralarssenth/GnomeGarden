extends TileMap

#tile map shortcut constants
const TILEMAP_SOURCE_ID = 0
const PLANT_TILEMAP_SOURCE_ID = 1
const BACKGROUND = 0
const PERMANENTS = 1
const FOREGROUND = 2
const CLEAR_SELECTION = 3
const PLANT_SELECTION = 4
const HARVEST_SELECTION = 5

#tile id shortcut constants
const HIGHLIGHT_ATLAS_COORDS = Vector2i(12,0)
const PASSABLE_DIRT_ATLAS_COORDS = Vector2i(7,0)
const IMPASSABLE_DIRT_ATLAS_COORDS = Vector2i(6,0)
const ROCK_ATLAS_COORDS = Vector2i(10, 0)
const PLANT_ATLAS = Vector2i(0, 0)
const PLANT_1A = 0
const PLANT_1B = 1
const PLANT_2A = 2
const PLANT_2B = 3

# Tutorial Text
var welcome = []

var days_until_game_over
var day_length

var game_mode

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_welcome():
	return welcome
	
func set_welcome(text):
	welcome.append_array(text)
	
func get_days():
	return days_until_game_over

func set_days(days):
	days_until_game_over = days

func get_day_length():
	return  day_length

func set_day_length(length):
	day_length = length

func get_game_mode():
	return game_mode

func set_game_mode(mode):
	match mode:
		Globals.GAME_MODES.STANDARD:
			game_mode = Globals.GAME_MODES.STANDARD
		Globals.GAME_MODES.SANDBOX:
			game_mode = Globals.GAME_MODES.SANDBOX
		
