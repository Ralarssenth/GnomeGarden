extends TileMap

# Tutorial Text
const WELCOME = [
	"Welcome to Gnome Garden!!", 
	"Click the Plant Seed button to get started."
	]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_welcome():
	return WELCOME
