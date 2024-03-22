extends CharacterBody2D

var movement_speed: float = 20.0
var movement_target_position: Vector2 = Vector2(0.0,0.0)

signal idle 
signal arrived
signal gnome_finished_busy_animation

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _animation_player = $AnimationPlayer
@onready var gnome_sprite = $Sprite2D
@onready var hat_sprite = $HatSprite

const GNOME_TEXTURES = [
	"res://assets/gnome/PNG/24x32/gnome-m-red_hat-NESW.png",
	"res://assets/gnome/PNG/24x32/gnome-m-green_hat-NESW.png",
	"res://assets/gnome/PNG/24x32/gnome-f-violet_hat-NESW.png",
	"res://assets/gnome/PNG/24x32/gnome-f-red_hat-NESW.png"
]

var construction_hat = preload("res://assets/gnome/hats/construction_hat.png")
var flower_hat = preload("res://assets/gnome/hats/flower_hat.png")
var fruits_hat = preload("res://assets/gnome/hats/fruits_hat.png")


var state = Globals.GNOME_STATE.IDLE
var job = Globals.GNOME_STATE.IDLE

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize_gnome_texture()
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 2.0
	navigation_agent.target_desired_distance = 8.0

	# Make sure to not await during _ready.
	call_deferred("actor_setup")
	
	set_state(Globals.GNOME_STATE.IDLE)

# Sets a random sprite sheet from the list to be the sprite's texture 
# Called on ready (when a gnome spawns in)
func randomize_gnome_texture():
	var i = randi_range(0, GNOME_TEXTURES.size()-1)
	var texture = load(GNOME_TEXTURES[i])
	gnome_sprite.set_texture(texture)

# Sets up the navigation on the first physics frame
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
	if navigation_agent.is_navigation_finished() and (state == Globals.GNOME_STATE.IDLE or state == Globals.GNOME_STATE.HAULING):
		var reachable = true
		if navigation_agent.is_target_reachable():
			emit_signal("arrived", movement_target_position, job, reachable, self)
			print("current state in delta: " + str(state))
			return
		else:
			reachable = false
			emit_signal("arrived", movement_target_position, job, reachable, self)
			return
	if state == Globals.GNOME_STATE.IDLE:
		navigate()
	if state == Globals.GNOME_STATE.HAULING:
		navigate()

# Tells the gnome to advance on his navigation path 
func navigate():
	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	move_and_slide()
	set_walk_animation()

# Sets the gnome's walking animation based on velocity vector
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

# Set's the gnome's job and gives a hat based on the job
func set_job(_job):
	job = _job
	print("gnome job set")
	match job:
		Globals.GNOME_STATE.IDLE:
			hat_sprite.set_visible(false)
		Globals.GNOME_STATE.CLEARING_DEBRIS:
			hat_sprite.set_texture(construction_hat)
			hat_sprite.set_visible(true)
		Globals.GNOME_STATE.PLANTING_SEED, Globals.GNOME_STATE.PLANTING_SEED2, Globals.GNOME_STATE.TENDING_PLANT:
			hat_sprite.set_texture(flower_hat)
			hat_sprite.set_visible(true)
		Globals.GNOME_STATE.HARVESTING, Globals.GNOME_STATE.HAULING:
			hat_sprite.set_texture(fruits_hat)
			hat_sprite.set_visible(true)


# Sets the gnome's current state
# Defines the gnome's jobs based on state
func set_state(_state):
	state = _state
	match state:
		Globals.GNOME_STATE.IDLE:
			set_job(Globals.GNOME_STATE.IDLE)
			emit_signal("idle", self)
			print("gnome state set to idle")
			
		Globals.GNOME_STATE.CLEARING_DEBRIS:
			print("gnome state set to clearing debris")
			_animation_player.play("busy")
			
		Globals.GNOME_STATE.PLANTING_SEED:
			print("gnome state set to planting seed")
			_animation_player.play("busy")
		
		Globals.GNOME_STATE.PLANTING_SEED2:
			print("gnome state set to planting seed2")
			_animation_player.play("busy")
			
		Globals.GNOME_STATE.TENDING_PLANT:
			print("gnome state set to tending plant")
			_animation_player.play("busy")
			
		Globals.GNOME_STATE.HARVESTING:
			print("gnome state set to harvesting plant")
			_animation_player.play("busy")
		
		Globals.GNOME_STATE.HAULING:
			print("gnome state set to hauling")
			set_job(Globals.GNOME_STATE.HAULING)
			set_movement_target(Vector2(0,0))

# Passes signals with additional params up to main when animation finishes
func _on_animation_player_animation_finished(_anim_name):
	if _anim_name == "busy":
		emit_signal("gnome_finished_busy_animation", job, movement_target_position, self)


