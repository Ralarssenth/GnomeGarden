extends Sprite2D

@onready var _animation_player = $AnimationPlayer

signal finished_growing
var map_position

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("finished_growing", Callable(get_parent().get_parent(), "_on_plant_finished_growing"))
	_animation_player.play("grow")
	map_position = get_position()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
