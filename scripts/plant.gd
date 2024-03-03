extends Sprite2D

@onready var _animation_player = $AnimationPlayer

signal needs_tending
var map_position

# Called when the node enters the scene tree for the first time.
func _ready():
	_animation_player.play("grow_1")
	map_position = get_position()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_animation_player_animation_finished(_anim_name):
	emit_signal("needs_tending", map_position)
	print("plant grow animation " +str(_anim_name) + " finished")
