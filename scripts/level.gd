extends TileMap

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
		
