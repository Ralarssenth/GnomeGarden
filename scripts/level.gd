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
const HIGHLIGHT_ATLAS_COORDS = Vector2i(0,1)
const DIRT1_ATLAS_COORDS = Vector2i(2,0)
const DIRT2_ATLAS_COORDS = Vector2i(3,0)
const DIRT3_ATLAS_COORDS = Vector2i(4,0)
const DIRT4_ATLAS_COORDS = Vector2i(5,0)
const DIRT5_ATLAS_COORDS = Vector2i(6,0)
const IMPASSABLE_DIRT_ATLAS_COORDS = Vector2i(1,0)
const ROCK_ATLAS_COORDS = Vector2i(1,1)

const PLANTS = {
	"PLANT_1": 
		[
		Vector2i(0,4), 
		Vector2i(1,4), 
		Vector2i(2,4), 
		Vector2i(3,4)
	], 
	"PLANT_2" : 
		[
		Vector2i(0,5),
		Vector2i(1,5),
		Vector2i(2,5),
		Vector2i(3,5)
	]
}
const PLANT_1_GROW_TIME = 10.0 
const PLANT_2_GROW_TIME = 20.0

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
		
func get_flowers():
	var plants = []
	for plant in PLANTS:
		for cell_id in PLANTS[plant]:
			plants.append_array(get_used_cells_by_id(
			FOREGROUND, 
			TILEMAP_SOURCE_ID,  
			cell_id
		))	
	
	var seedlings = []
	for plant in PLANTS:
		seedlings.append_array(get_used_cells_by_id(
			FOREGROUND, 
			TILEMAP_SOURCE_ID,  
			PLANTS[plant][0]
		))
	
	return (plants.size() - seedlings.size())
	
func get_biodiversity():
	var biodiv = 0
	for plant in PLANTS:
		var plant_holder = []
		for cell_id in PLANTS[plant]:
			plant_holder.append_array(get_used_cells_by_id(
				FOREGROUND, 
				TILEMAP_SOURCE_ID,  
				cell_id
			))	
		if not plant_holder.is_empty():
			biodiv += 1
	return biodiv
