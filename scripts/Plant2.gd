extends Sprite2D

@onready var _animation_player = $AnimationPlayer

signal needs_tending
var map_position

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("needs_tending", Callable(get_parent().get_parent(), "_on_plant_needs_tending"))
	_animation_player.play("grow")
	map_position = get_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Passes the needs_tending signal up to main
func _on_animation_player_animation_finished(_anim_name):
	emit_signal("needs_tending", map_position)
	print("plant2 grow animation finished")
