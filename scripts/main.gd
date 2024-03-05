extends Node2D

@onready var tutorial_level = $TutorialLevel
@onready var gnome = $Gnome
@onready var hud = $HUD


var tilemap_source_id = 0
var plant_tilemap_source_id = 1
var background = 0
var foreground = 2
var clearSelection = 3
var plantSelection = 4

var highlight_atlas_coords = Vector2i(12,0)
var passable_dirt_atlas_coords = Vector2(7,0)
var impassable_dirt_atlas_coords = Vector2(6,0)
var plant_id = Vector2i(0, 0)
var plant_1 = 0
var plant_2 = 1

var clearHighlightColor = Color(0,0,0.5,0.5)
var plantHighlightColor = Color(0,0.5,0,0.5)
var removeColor = Color(1,1,1,1)
var highlightColor = Color(1,1,1,0.4)
var removeHighlightColor = Color(1,1,1,0)

var clearDebrisPos = []
var plantSeedPos = []
var seedlingPos = []
var flowersPos = []
var harvestPos = []

var flower_count = flowersPos.size()

enum MODES {NULL, CLEAR_DEBRIS, PLANT}
var mode = MODES.NULL
# THIS ENUM MUST MATCH THE ONE IN GNOME.GD
enum GNOME_STATE {IDLE, CLEARING_DEBRIS, PLANTING_SEED, TENDING_PLANT, HAULING}

# Called when the node enters the scene tree for the first time.
func _ready():
	register_buttons()
	register_gnome_signals()
	initial_hud_messages()
	

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

# Connects all the custom signals from gnome
# Called in the ready function
func register_gnome_signals():
	gnome.connect("idle", _on_gnome_idle)
	gnome.connect("arrived", _on_gnome_arrived)
	gnome.connect("gnome_finished_busy_animation", _on_gnome_finished_busy_animation)

# Called on menu button press
func _on_button_pressed(name):
	if mode == MODES.NULL:
		match name:
			"ClearDebrisButton":
				set_mode(MODES.CLEAR_DEBRIS)
			"PlantCropMenuButton":
				set_mode(MODES.PLANT)

	else:
		set_mode(MODES.NULL)

# handles player inputs
func _unhandled_input(event):
	var mouse_pos = get_global_mouse_position()
	var tile_mouse_pos = tutorial_level.local_to_map(mouse_pos)
	match mode:
		MODES.CLEAR_DEBRIS:
			# left click in CLEAR MODE
			if event.is_action_pressed("click"):
				tutorial_level.set_cell(clearSelection, tile_mouse_pos, tilemap_source_id, highlight_atlas_coords)
				clearDebrisPos.push_back(tile_mouse_pos)
				print("appended clear debris array")
				
			#right click in CLEAR MODE
			if event.is_action_pressed("right click"):
				tutorial_level.erase_cell(clearSelection, tile_mouse_pos)
				clearDebrisPos.erase(tile_mouse_pos)
				print("erased a position from the clear debris array")
			
		MODES.PLANT:
				#left click in PLANT MODE
			if event.is_action_pressed("click"):
					tutorial_level.set_cell(plantSelection, tile_mouse_pos, tilemap_source_id, highlight_atlas_coords)
					plantSeedPos.push_back(tile_mouse_pos)
					print("appended plant seed array")
			
			#right click in PLANT MODE
			if event.is_action_pressed("right click"):
				tutorial_level.erase_cell(plantSelection, tile_mouse_pos)
				plantSeedPos.erase(tile_mouse_pos)
		_:
			pass

# Opening game messages
func initial_hud_messages():
	hud.update_message_list("Welcome to Gnome Garden!")
	hud.update_message_list("Click the Plant Seed button to get started.")
	hud.show_message_text()

#Sets the player's game mode
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

# This is the logic for the order of operations on gnome jobs
# gnomes will check the tending array first, then check the debris array, then check the planting array
# if all arrays are empty, gnome picks a random spot near the tree to path to
func _on_gnome_idle():
	var pos
	var job
	print("gnome idle signal caught")
	if not seedlingPos.is_empty():
		pos = tutorial_level.map_to_local(seedlingPos.pop_front())
		job = GNOME_STATE.TENDING_PLANT
		print("gnome told to tend")
		
	elif not clearDebrisPos.is_empty():
		pos = tutorial_level.map_to_local(clearDebrisPos.pop_front())
		job = GNOME_STATE.CLEARING_DEBRIS
		
	elif not plantSeedPos.is_empty():
		pos = tutorial_level.map_to_local(plantSeedPos.pop_front())
		job = GNOME_STATE.PLANTING_SEED
		
	else:
		# pick a random spot on the map
		pos = Vector2(randf_range(-32.0, 32.0),randf_range(-32.0, 32.0))
		job = GNOME_STATE.IDLE

	gnome.set_movement_target(pos)
	gnome.set_job(job)
	print("gnome sent new position data")

# Tells a gnome what to do with a cell once they arrive 
# based on their assigned job and if they were able to reach their destination
func _on_gnome_arrived(pos: Vector2, job, reachable):
	print("gnome has arrived")
	var map_pos = tutorial_level.local_to_map(pos)
	var foreground_cells = tutorial_level.get_used_cells(foreground)
	
	match job:
		GNOME_STATE.IDLE:
			gnome.set_state(job)
		
		GNOME_STATE.CLEARING_DEBRIS:
			if not reachable:
				tutorial_level.erase_cell(clearSelection, map_pos)
				gnome.set_state(GNOME_STATE.IDLE)
			
			if foreground_cells.find(map_pos) != -1:
				print("gnome told to clear")
				tutorial_level.erase_cell(clearSelection, map_pos)
				gnome.set_state(job)
			
			else:
				print("gnome state set to idle on arrival because foreground cell is empty")
				tutorial_level.erase_cell(clearSelection, map_pos)
				gnome.set_state(GNOME_STATE.IDLE)
			
		GNOME_STATE.PLANTING_SEED:
			if not reachable:
				tutorial_level.erase_cell(plantSelection, map_pos)
				gnome.set_state(GNOME_STATE.IDLE)
				
			else:
				if foreground_cells.find(map_pos) != -1:
					print("gnome won't plant here because foreground cell is occupied")
					tutorial_level.erase_cell(plantSelection, map_pos)
					gnome.set_state(GNOME_STATE.IDLE)
					
				else:
					print("gnome told to plant seed upon arrival")
					tutorial_level.erase_cell(plantSelection, map_pos)
					gnome.set_state(job)
		
		GNOME_STATE.TENDING_PLANT:
			if not reachable:
				gnome.set_state(GNOME_STATE.IDLE)
			
			else:
				gnome.set_state(job)

# Updates the tilemap based on what the gnome was just doing
# Sets the gnome back to idle now that he's done his job
func _on_gnome_finished_busy_animation(job, pos):
	print("busy animation finished")
	var map_pos = tutorial_level.local_to_map(pos)
	match job:
		GNOME_STATE.CLEARING_DEBRIS:
			tutorial_level.erase_cell(foreground, map_pos)
			tutorial_level.set_cell(background, map_pos, tilemap_source_id, passable_dirt_atlas_coords)
			print("gnome set to idle after clearing debris")
			
			if flowersPos.find(map_pos) != -1:
				flowersPos.erase(map_pos)
				update_flower_count()
			
		GNOME_STATE.PLANTING_SEED:
			tutorial_level.set_cell(background, map_pos, tilemap_source_id, impassable_dirt_atlas_coords)
			#spawn a plant using the tilemap
			tutorial_level.set_cell(foreground, map_pos, plant_tilemap_source_id, plant_id, plant_1)
			print("gnome set to idle after planting seed")
		
		GNOME_STATE.TENDING_PLANT:
			# advance to next animation on the plant and play it
			tutorial_level.erase_cell(foreground, map_pos)
			tutorial_level.set_cell(foreground, map_pos, plant_tilemap_source_id, plant_id, plant_2)
			print("gnome set to idle after tending plant")

		GNOME_STATE.IDLE:
			print("busy while idle??")
	
	gnome.set_state(GNOME_STATE.IDLE)

func update_flower_count():
	flower_count = flowersPos.size()
	hud.update_flower_counter(flower_count)

# Adds plant coords to the tending array
func _on_plant_needs_tending(pos: Vector2):
	var map_pos = tutorial_level.local_to_map(pos)
	seedlingPos.push_back(map_pos)
	flowersPos.push_back(map_pos)
	update_flower_count()
	print("plant added to tending queue")

func _on_plant_finished_growing(pos: Vector2):
	var map_pos = tutorial_level.local_to_map(pos)
	harvestPos.push_back(map_pos)
	print("plant added to harvest queue")
