extends CharacterBody2D

var movement_speed: float = 4.0
var movement_target_position: Vector2 = Vector2(0.0,0.0)

signal idle 
signal arrived

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

enum STATE {IDLE, WALKING, CLEARING_DEBRIS, PLANTING_SEED, TENDING_PLANT, HAULING}
var state = STATE.IDLE

# Called when the node enters the scene tree for the first time.
func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

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
	if navigation_agent.is_navigation_finished():
		emit_signal("arrived", movement_target_position)
		set_state(STATE.IDLE)
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	move_and_slide()
	
func set_state(_state):
	match state:
		STATE.IDLE:
			emit_signal("idle")
			print("state set to idle")
			
		STATE.WALKING:
			pass
			
		STATE.CLEARING_DEBRIS:
			pass
			
		STATE.PLANTING_SEED:
			pass
			
		STATE.TENDING_PLANT:
			pass
			
		STATE.HAULING:
			pass

