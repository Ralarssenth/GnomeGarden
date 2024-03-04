extends Node2D

@onready var tutorial_level = $TutorialLevel
@onready var gnome = $Gnome

const plant_scene = preload("res://scenes/plant.tscn")

var tilemap_source_id = 0
var plant_tilemap_source_id = 1
var background = 0
var foreground = 2
var clearSelection = 3
var plantSelection = 4

var highlight_atlas_coords = Vector2i(12,0)
var passable_dirt_atlas_coords = Vector2(7,0)
var impassable_dirt_atlas_coords = Vector2(6,0)
var plant_id = Vector2(0,0)

var clearHighlightColor = Color(0,0,0.5,0.5)
var plantHighlightColor = Color(0,0.5,0,0.5)
var removeColor = Color(1,1,1,1)
var highlightColor = Color(1,1,1,0.4)
var removeHighlightColor = Color(1,1,1,0)

var clearDebrisPos = []
var plantSeedPos = []
var seedlingPos = []

enum MODES {NULL, CLEAR_DEBRIS, PLANT}
var mode = MODES.NULL
# THIS ENUM MUST MATCH THE ONE IN GNOME
enum STATE {IDLE, CLEARING_DEBRIS, PLANTING_SEED, TENDING_PLANT, HAULING}

# Called when the node enters the scene tree for the first time.
func _ready():
	register_buttons()
	register_gnome_signals()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Gets all the buttons on the screen and connects their signals
# Called in the ready function
func register_buttons():
	var buttons = get_tree().get_nodes_in_group("buttons") # gets all the buttons by group
	for button in buttons:
		# Creates a callable for the node's recieve signal so that the button name can be passed as an extra parameter
		var callable = Callable(self, "_on_button_pressed").bind(button.name)
		# Connects the button's signal to the node's callable
		button.connect("pressed", callable)

# Connects all the cusutom signals from gnome
# Called in the ready function
func register_gnome_signals():
	gnome.connect("idle", _on_gnome_idle)
	gnome.connect("arrived", _on_gnome_arrived)
	gnome.connect("gnome_finished_busy_animation", _on_gnome_finished_busy_animation)

# Called on menu button toggle
func _on_button_pressed(name):
	if mode == MODES.NULL:
		match name:
			"ClearDebrisButton":
				set_mode(MODES.CLEAR_DEBRIS)
			"PlantCropMenuButton":
				set_mode(MODES.PLANT)

	else:
		set_mode(MODES.NULL)


func _unhandled_input(event):
	
	# left click in CLEAR MODE
	if event.is_action_pressed("click") and mode == MODES.CLEAR_DEBRIS:
		var mouse_pos = get_global_mouse_position()
		var tile_mouse_pos = tutorial_level.local_to_map(mouse_pos)
		
		# set the highlight
		tutorial_level.set_cell(clearSelection, tile_mouse_pos, tilemap_source_id, highlight_atlas_coords)
		# add the pos to the clear debris array
		clearDebrisPos.push_back(tile_mouse_pos)
		print("appended clear debris array")
	
	#left click in PLANT MODE
	if event.is_action_pressed("click") and mode == MODES.PLANT:
		var mouse_pos = get_global_mouse_position()
		var tile_mouse_pos = tutorial_level.local_to_map(mouse_pos)
		
		#set the highlight
		tutorial_level.set_cell(plantSelection, tile_mouse_pos, tilemap_source_id, highlight_atlas_coords)
		# add the pos to the clear debris array
		plantSeedPos.push_back(tile_mouse_pos)
		print("appended plant seed array")
	
	#right click in CLEAR MODE
	if event.is_action_pressed("right click") and mode == MODES.CLEAR_DEBRIS:
		var mouse_pos = get_global_mouse_position()
		var tile_mouse_pos = tutorial_level.local_to_map(mouse_pos)
		
		# erase the highlight
		tutorial_level.erase_cell(clearSelection, tile_mouse_pos)
		# remove the position from the array
		clearDebrisPos.erase(tile_mouse_pos)

	#right click in PLANT MODE
	if event.is_action_pressed("right click") and mode == MODES.PLANT:
		var mouse_pos = get_global_mouse_position()
		var tile_mouse_pos = tutorial_level.local_to_map(mouse_pos)
		
		# erase the highlight
		tutorial_level.erase_cell(plantSelection, tile_mouse_pos)
		# remove the position from the array
		clearDebrisPos.erase(tile_mouse_pos)
	
func set_mode(_mode):
	mode = _mode
	
	match mode:
		MODES.NULL:
			tutorial_level.set_layer_modulate(clearSelection, removeHighlightColor)
			tutorial_level.set_layer_modulate(plantSelection, removeHighlightColor)
			tutorial_level.set_layer_modulate(background, removeColor)
			
		MODES.CLEAR_DEBRIS:
			tutorial_level.set_layer_modulate(clearSelection, highlightColor)
			tutorial_level.set_layer_modulate(background, clearHighlightColor)
			
		MODES.PLANT:
			tutorial_level.set_layer_modulate(plantSelection, highlightColor)
			tutorial_level.set_layer_modulate(background, plantHighlightColor)

func _on_gnome_idle():
	var pos
	var job
	print("gnome idle signal caught")
	if not seedlingPos.is_empty():
		pos = tutorial_level.map_to_local(seedlingPos.pop_front())
		job = STATE.TENDING_PLANT
		print("gnome told to tend")
		
	elif not clearDebrisPos.is_empty():
		pos = tutorial_level.map_to_local(clearDebrisPos.pop_front())
		job = STATE.CLEARING_DEBRIS
		
	elif not plantSeedPos.is_empty():
		pos = tutorial_level.map_to_local(plantSeedPos.pop_front())
		job = STATE.PLANTING_SEED
		
	else:
		# pick a random spot on the map
		pos = Vector2(randf_range(-32.0, 32.0),randf_range(-32.0, 32.0))
		job = STATE.IDLE

	gnome.set_movement_target(pos)
	gnome.set_job(job)
	print("gnome sent new position data")

func _on_gnome_arrived(pos: Vector2, job, reachable):
	print("gnome has arrived")
	var map_pos = tutorial_level.local_to_map(pos)
	var foreground_cell = tutorial_level.get_cell_tile_data(foreground, map_pos)
	
	print(foreground_cell)
	
	match job:
		STATE.IDLE:
			gnome.set_state(STATE.IDLE)
		
		STATE.CLEARING_DEBRIS:
			if not reachable:
				tutorial_level.erase_cell(clearSelection, map_pos)
				gnome.set_job(STATE.IDLE)
				gnome.set_state(STATE.IDLE)
			
			elif foreground_cell:
				var debris = foreground_cell.get_custom_data("debris")
				print("debris bool: " + str(debris))
				
				if debris:
					print("gnome told to clear")
					tutorial_level.erase_cell(clearSelection, map_pos)
					gnome.set_state(job)
					
				else:
					print("gnome state set to idle on arrival because cell is not debris")
					gnome.set_state(STATE.IDLE)
			
			else:
				print("gnome state set to idle on arrival because foreground cell is empty")
				tutorial_level.erase_cell(clearSelection, map_pos)
				gnome.set_job(STATE.IDLE)
				gnome.set_state(STATE.IDLE)
			
		STATE.PLANTING_SEED:
			if not reachable:
				tutorial_level.erase_cell(plantSelection, map_pos)
				gnome.set_job(STATE.IDLE)
				gnome.set_state(STATE.IDLE)
			
			elif foreground_cell:
				print("gnome won't plant here because foreground cell is occupied")
				tutorial_level.erase_cell(plantSelection, map_pos)
				gnome.set_job(STATE.IDLE)
			
			else:
				print("gnome told to plant seed upon arrival")
				tutorial_level.erase_cell(plantSelection, map_pos)
				gnome.set_state(job)
		
		STATE.TENDING_PLANT:
			#this logic will need to be updated when plant becomes a cell on the tilemap
			#right now the gnome will tend all plants from any distance
			gnome.set_state(job)
		

func _on_gnome_finished_busy_animation(job, pos):
	print("busy animation finished")
	var gnomeJob = job
	match gnomeJob:
		STATE.CLEARING_DEBRIS:
			var map_pos = tutorial_level.local_to_map(pos)
			tutorial_level.erase_cell(foreground, map_pos)
			tutorial_level.set_cell(background, map_pos, tilemap_source_id, passable_dirt_atlas_coords)
			gnome.set_state(STATE.IDLE)
			print("gnome set to idle after clearing debris")
			
		STATE.PLANTING_SEED:
			var map_pos = tutorial_level.local_to_map(pos)
			tutorial_level.set_cell(background, map_pos, tilemap_source_id, impassable_dirt_atlas_coords)
			
			# spawn a plant at ABSOLUTE pos NOT map_pos
			var plant = plant_scene.instantiate()
			plant.connect("needs_tending", Callable(self, "_on_plant_needs_tending"))
			plant.set_position(pos)
			add_child(plant)
			
			gnome.set_state(STATE.IDLE)
			print("gnome set to idle after planting seed")
		
		STATE.TENDING_PLANT:
			gnome.set_state(STATE.IDLE)
			# advance to next animation on the plant and play it
			
		STATE.IDLE:
			print("busy while idle??")

func _on_plant_needs_tending(pos: Vector2):
	var map_pos = tutorial_level.local_to_map(pos)
	seedlingPos.push_back(map_pos)
	print("plant added to tending queue")
