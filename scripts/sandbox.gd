extends "res://scripts/level.gd"


# Called when the node enters the scene tree for the first time.
func _ready():
	set_welcome([
		"Welcome to Gnome Garden: Sandbox Mode!!", 
		"This mode has no time limit, so garden to your heart's content!"
		])
	set_game_mode(GAME_MODES.SANDBOX)
	set_day_length(10.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
