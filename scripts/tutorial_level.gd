extends "res://scripts/level.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	set_welcome([
		"Welcome to Gnome Garden!!", 
		"Click the Plant Seed button to get started."
		])
	set_game_mode(Globals.GAME_MODES.STANDARD)
	set_days(90)
	set_day_length(10.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
