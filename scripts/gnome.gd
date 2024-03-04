extends CharacterBody2D

var movement_speed: float = 20.0
var movement_target_position: Vector2 = Vector2(0.0,0.0)

signal idle 
signal arrived
signal gnome_finished_busy_animation

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _animation_player = $AnimationPlayer
@onready var area2d = $Area2D

enum STATE {IDLE, CLEARING_DEBRIS, PLANTING_SEED, TENDING_PLANT, HAULING}
var state = STATE.IDLE
var job = STATE.IDLE

# Called when the node enters the scene tree for the first time.
func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 2.0
	navigation_agent.target_desired_distance = 8.0

	# Make sure to not await during _ready.
	call_deferred("actor_setup")
	
	set_state(STATE.IDLE)

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(movement_target_position)

# update navigation agent target position
func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target
	movement_target_position = movement_target

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if navigation_agent.is_navigation_finished() and state == STATE.IDLE:
		var reachable = true
		if navigation_agent.is_target_reachable():
			emit_signal("arrived", movement_target_position, job, reachable)
			print("current state in delta: " + str(state))
			return
		else:
			reachable = false
			emit_signal("arrived", movement_target_position, job, reachable)
			return
	if state == STATE.IDLE:
		navigate()

func navigate():
	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	move_and_slide()
	set_walk_animation()

func set_walk_animation():
	var speed = get_real_velocity()
	if speed.x > 0 and abs(speed.x) > abs(speed.y):
		_animation_player.play("walk_right")
	elif speed.x < 0 and abs(speed.x) > abs(speed.y):
		_animation_player.play("walk_left")
	elif speed.y > 0:
		_animation_player.play("walk_down")
	else:
		_animation_player.play("walk_up")

func set_job(_job):
	job = _job
	print("gnome job set")

func set_state(_state):
	state = _state
	match state:
		STATE.IDLE:
			emit_signal("idle")
			print("gnome state set to idle")
			
		STATE.CLEARING_DEBRIS:
			print("gnome state set to clearing debris")
			_animation_player.stop()
			_animation_player.play("busy")
			
		STATE.PLANTING_SEED:
			if area2d.has_overlapping_areas():
				set_state(STATE.IDLE)
				print("gnome won't plant on top of an existing seedling")
			else:
				print("gnome state set to planting seed")
				_animation_player.stop()
				_animation_player.play("busy")
			
		STATE.TENDING_PLANT:
			print("gnome state set to tending plant")
			_animation_player.stop()
			_animation_player.play("busy")
			
		STATE.HAULING:
			pass

func _on_animation_player_animation_finished(_anim_name):
	if _anim_name == "busy":
		emit_signal("gnome_finished_busy_animation", job, movement_target_position)


