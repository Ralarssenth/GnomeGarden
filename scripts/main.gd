extends Node2D

var gnome = preload("res://scenes/gnome.tscn")
var tutorial_level = preload("res://scenes/tutorial_level.tscn")

@onready var camera = $Camera2D
@onready var hud = $HUD

#tile map shortcut constants
const TILEMAP_SOURCE_ID = 0
const PLANT_TILEMAP_SOURCE_ID = 1
const BACKGROUND = 0
const PERMANENTS = 1
const FOREGROUND = 2
const CLEAR_SELECTION = 3
const PLANT_SELECTION = 4
const HARVEST_SELECTION = 5

#tile id shortcut constants
const HIGHLIGHT_ATLAS_COORDS = Vector2i(12,0)
const PASSABLE_DIRT_ATLAS_COORDS = Vector2i(7,0)
const IMPASSABLE_DIRT_ATLAS_COORDS = Vector2i(6,0)
const ROCK_ATLAS_COORDS = Vector2i(10, 0)
const PLANT_ATLAS = Vector2i(0, 0)
const PLANT_1A = 0
const PLANT_1B = 1
const PLANT_2A = 2
const PLANT_2B = 3

#color shortcut constants
const CLEAR_HIGHLIGHT_COLOR = Color(0,0,0.5,0.5)
const PLANT_HIGHLIGHT_COLOR = Color(0,0.5,0,0.5)
const REMOVE_COLOR = Color(1,1,1,1)
const HIGHLIGHT_COLOR = Color(1,1,1,0.4)
const REMOVE_HIGHLIGHT_COLOR = Color(1,1,1,0)

# level tracking
var current_level
var in_level = false
var camera_zoom

# object tracking
var gnomes = []
var clearDebrisPos = []
var plantSeedPos = []
var plantSeed2Pos = []
var seedlingPos = []
var flowersPos = []
var harvestablePos = []
var harvestPos = []

# score keeping
var flower_count = flowersPos.size()
var fruit_count = 0

# state tracking
enum MODES {NULL, CLEAR_DEBRIS, PLANT, PLANT2, HARVEST, DRAG}
var mode = MODES.NULL
# THIS ENUM MUST MATCH THE ONE IN GNOME.GD IDENTICALLY
enum GNOME_STATE {IDLE, CLEARING_DEBRIS, PLANTING_SEED, PLANTING_SEED2, TENDING_PLANT, HARVESTING, HAULING}

# Called when the node enters the scene tree for the first time.
func _ready():
	register_buttons()
	hud.show_menu_hud()
	hud.connect("game_over", game_over)

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

func start_level(level):
	current_level = level.instantiate()
	add_child(current_level)
	in_level = true
	camera_zoom = camera.get_zoom()
	hud.show_game_hud()
	spawn_gnome()
	update_hud_messages(current_level.get_welcome())
	update_garden_score()
	
func game_over():
	update_hud_messages(["Game Over", "Thanks for gardening!"])
	get_tree().paused = true

# Connects all the custom signals from gnome
# Called in the ready function
func register_gnome_signals(current_gnome):
	current_gnome.connect("idle", _on_gnome_idle)
	current_gnome.connect("arrived", _on_gnome_arrived)
	current_gnome.connect("gnome_finished_busy_animation", _on_gnome_finished_busy_animation)

# Called on menu button press
func _on_button_pressed(name):
	if mode == MODES.NULL:
		match name:
			"ClearDebrisButton":
				set_mode(MODES.CLEAR_DEBRIS)
			"PlantCropMenuButton":
				set_mode(MODES.PLANT)
			"HarvestButton":
				set_mode(MODES.HARVEST)
			"PlantCrop2MenuButton":
				set_mode(MODES.PLANT2)
			"TutorialLevel":
				start_level(tutorial_level)

	else:
		set_mode(MODES.NULL)

# handles player inputs
func _unhandled_input(event):
	var mouse_pos = get_global_mouse_position()
	if in_level:
		if event.is_action_pressed("scroll up") and camera_zoom < Vector2(5, 5):
			camera_zoom = camera.get_zoom()
			camera_zoom += Vector2(1,1)
			camera.set_zoom(camera_zoom)
		
		if event.is_action_pressed("scroll down") and camera_zoom > Vector2(1, 1):
			camera_zoom = camera.get_zoom()
			camera_zoom -= Vector2(1,1)
			camera.set_zoom(camera_zoom)
		
		if event.is_action_pressed("middle click"):
			set_mode(MODES.DRAG)
		if event.is_action_released("middle click"):
			set_mode(MODES.NULL)
		
		var tile_mouse_pos = current_level.local_to_map(mouse_pos)
		match mode:
			MODES.CLEAR_DEBRIS:
				# left click in CLEAR MODE
				if event.is_action_pressed("click"):
					current_level.set_cell(CLEAR_SELECTION, tile_mouse_pos, TILEMAP_SOURCE_ID, HIGHLIGHT_ATLAS_COORDS)
					clearDebrisPos.push_back(tile_mouse_pos)
					print("appended clear debris array")
					
				#right click in CLEAR MODE
				if event.is_action_pressed("right click"):
					current_level.erase_cell(CLEAR_SELECTION, tile_mouse_pos)
					clearDebrisPos.erase(tile_mouse_pos)
					print("erased a position from the clear debris array")
				
			MODES.PLANT:
				#left click in PLANT MODE
				if event.is_action_pressed("click"):
						current_level.set_cell(PLANT_SELECTION, tile_mouse_pos, TILEMAP_SOURCE_ID, HIGHLIGHT_ATLAS_COORDS)
						plantSeedPos.push_back(tile_mouse_pos)
						print("appended plant seed array")
				
				#right click in PLANT MODE
				if event.is_action_pressed("right click"):
					current_level.erase_cell(PLANT_SELECTION, tile_mouse_pos)
					plantSeedPos.erase(tile_mouse_pos)
			
			MODES.PLANT2:
				if event.is_action_pressed("click"):
						current_level.set_cell(PLANT_SELECTION, tile_mouse_pos, TILEMAP_SOURCE_ID, HIGHLIGHT_ATLAS_COORDS)
						plantSeed2Pos.push_back(tile_mouse_pos)
						print("appended plant seed array")
				#right click in PLANT MODE
				if event.is_action_pressed("right click"):
					current_level.erase_cell(PLANT_SELECTION, tile_mouse_pos)
					plantSeedPos.erase(tile_mouse_pos)
			
			MODES.HARVEST:
				#left click in HARVEST MODE
				if event.is_action_pressed("click"):
					if harvestablePos.find(tile_mouse_pos) != -1:
						current_level.set_cell(HARVEST_SELECTION, tile_mouse_pos, TILEMAP_SOURCE_ID, HIGHLIGHT_ATLAS_COORDS)
						harvestPos.push_back(tile_mouse_pos)
				#right click in HARVEST MODE
				if event.is_action_pressed("right click"):
					current_level.erase_cell(HARVEST_SELECTION, tile_mouse_pos)
					harvestPos.erase(tile_mouse_pos)
			
			MODES.DRAG:
				if event is InputEventMouseMotion:
					var camera_position = camera.get_position()
					camera_position += - (event.relative / camera_zoom)
					camera.set_position(camera_position)
			
			_:
				pass

#Sets the player's game mode
func set_mode(_mode):
	mode = _mode
	
	match mode:
		MODES.NULL:
			current_level.set_layer_modulate(CLEAR_SELECTION, REMOVE_HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(PLANT_SELECTION, REMOVE_HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(HARVEST_SELECTION, REMOVE_HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(BACKGROUND, REMOVE_COLOR)
			
		MODES.CLEAR_DEBRIS:
			current_level.set_layer_modulate(CLEAR_SELECTION, HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(BACKGROUND, CLEAR_HIGHLIGHT_COLOR)
			
		MODES.PLANT:
			current_level.set_layer_modulate(PLANT_SELECTION, HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(BACKGROUND, PLANT_HIGHLIGHT_COLOR)
		
		MODES.PLANT2:
			current_level.set_layer_modulate(PLANT_SELECTION, HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(BACKGROUND, PLANT_HIGHLIGHT_COLOR)
		
		MODES.HARVEST:
			current_level.set_layer_modulate(BACKGROUND, PLANT_HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(HARVEST_SELECTION, HIGHLIGHT_COLOR)

func spawn_gnome():
	var new_gnome = gnome.instantiate()
	new_gnome.set_position(Vector2(0,0))
	add_child(new_gnome)
	register_gnome_signals(new_gnome)
	gnomes.push_back(new_gnome)

# This is the logic for the order of operations on gnome jobs
# gnomes will check the tending array first, then check the debris array, then check the planting array
# if all arrays are empty, gnome picks a random spot near the tree to path to
func _on_gnome_idle(current_gnome):
	var pos
	var job
	if not seedlingPos.is_empty():
		pos = current_level.map_to_local(seedlingPos.pop_front())
		job = GNOME_STATE.TENDING_PLANT
		print("gnome told to tend")
	
	elif not harvestPos.is_empty():
		pos = current_level.map_to_local(harvestPos.pop_front())
		job = GNOME_STATE.HARVESTING
		print("gnome told to harvest")
		
	elif not clearDebrisPos.is_empty():
		pos = current_level.map_to_local(clearDebrisPos.pop_front())
		job = GNOME_STATE.CLEARING_DEBRIS
		print("gnome told to clear debris")
		
	elif not plantSeedPos.is_empty():
		pos = current_level.map_to_local(plantSeedPos.pop_front())
		job = GNOME_STATE.PLANTING_SEED
		print("gnome told to plant seed")
		
	elif not plantSeed2Pos.is_empty():
		pos = current_level.map_to_local(plantSeed2Pos.pop_front())
		job = GNOME_STATE.PLANTING_SEED2
		print("gnome told to plant seed2")
		
	else:
		# pick a random spot on the map
		pos = Vector2(randf_range(-32.0, 32.0),randf_range(-32.0, 32.0))
		job = GNOME_STATE.IDLE
		print("gnome told to idle")

	current_gnome.set_movement_target(pos)
	current_gnome.set_job(job)
	print("gnome sent new position data")

# Tells a gnome what to do with a cell once they arrive 
# based on their assigned job and if they were able to reach their destination
func _on_gnome_arrived(pos: Vector2, job, reachable, current_gnome):
	print("gnome has arrived")
	var map_pos = current_level.local_to_map(pos)
	var foreground_cells = current_level.get_used_cells(FOREGROUND)
	var permanent_cells = current_level.get_used_cells(PERMANENTS)
	
	match job:
		GNOME_STATE.IDLE:
			current_gnome.set_state(job)
		
		GNOME_STATE.CLEARING_DEBRIS:
			if not reachable:
				current_level.erase_cell(CLEAR_SELECTION, map_pos)
				current_gnome.set_state(GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
			
			elif foreground_cells.find(map_pos) != -1:
				print("gnome told to clear")
				current_level.erase_cell(CLEAR_SELECTION, map_pos)
				current_gnome.set_state(job)
			
			else:
				print("gnome state set to idle on arrival because foreground cell is empty")
				current_level.erase_cell(CLEAR_SELECTION, map_pos)
				current_gnome.set_state(GNOME_STATE.IDLE)
			
		GNOME_STATE.PLANTING_SEED, GNOME_STATE.PLANTING_SEED2:
			if not reachable:
				current_level.erase_cell(PLANT_SELECTION, map_pos)
				current_gnome.set_state(GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
				
			elif foreground_cells.find(map_pos) != -1 or permanent_cells.find(map_pos) != -1:
				print("gnome won't plant here because foreground cell is occupied")
				current_level.erase_cell(PLANT_SELECTION, map_pos)
				current_gnome.set_state(GNOME_STATE.IDLE)
					
			else:
				print("gnome told to plant seed upon arrival")
				current_level.erase_cell(PLANT_SELECTION, map_pos)
				current_gnome.set_state(job)
		
		GNOME_STATE.TENDING_PLANT:
			if not reachable:
				current_gnome.set_state(GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
			
			else:
				current_gnome.set_state(job)
		
		GNOME_STATE.HARVESTING:
			if not reachable:
				current_gnome.set_state(GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
			#todo: add a check for if harvestable
			else:
				current_gnome.set_state(job)
		
		GNOME_STATE.HAULING:
			fruit_count = fruit_count + 1
			hud.update_fruit_counter(fruit_count)
			current_gnome.set_state(GNOME_STATE.IDLE)
			hud.update_plant_button_visibility(fruit_count)

# Updates the tilemap based on what the gnome was just doing
# Sets the gnome back to idle now that he's done his job
func _on_gnome_finished_busy_animation(job, pos, current_gnome):
	print("busy animation finished")
	var map_pos = current_level.local_to_map(pos)
	match job:
		GNOME_STATE.IDLE:
			print("busy while idle??")
			
		GNOME_STATE.CLEARING_DEBRIS:
			current_level.erase_cell(FOREGROUND, map_pos)
			current_level.set_cell(BACKGROUND, map_pos, TILEMAP_SOURCE_ID, PASSABLE_DIRT_ATLAS_COORDS)
	
			if flowersPos.find(map_pos) != -1:
				flowersPos.erase(map_pos)
				update_flower_count()
				
			update_garden_score()
			current_gnome.set_state(GNOME_STATE.IDLE)
			print("gnome set to idle after clearing debris")
			
		GNOME_STATE.PLANTING_SEED:
			current_level.set_cell(BACKGROUND, map_pos, TILEMAP_SOURCE_ID, IMPASSABLE_DIRT_ATLAS_COORDS)
			current_level.set_cell(FOREGROUND, map_pos, PLANT_TILEMAP_SOURCE_ID, PLANT_ATLAS, PLANT_1A)
			current_gnome.set_state(GNOME_STATE.IDLE)
			print("gnome set to idle after planting seed")
		
		GNOME_STATE.PLANTING_SEED2:
			current_level.set_cell(BACKGROUND, map_pos, TILEMAP_SOURCE_ID, IMPASSABLE_DIRT_ATLAS_COORDS)
			current_level.set_cell(FOREGROUND, map_pos, PLANT_TILEMAP_SOURCE_ID, PLANT_ATLAS, PLANT_2A)
			current_gnome.set_state(GNOME_STATE.IDLE)
			print("gnome set to idle after planting seed2")
		
		GNOME_STATE.TENDING_PLANT:
			var seedling_id = current_level.get_cell_alternative_tile(FOREGROUND, map_pos)
			if seedling_id == PLANT_1A:
				current_level.set_cell(FOREGROUND, map_pos, PLANT_TILEMAP_SOURCE_ID, PLANT_ATLAS, PLANT_1B)
			elif seedling_id == PLANT_2A:
				current_level.set_cell(FOREGROUND, map_pos, PLANT_TILEMAP_SOURCE_ID, PLANT_ATLAS, PLANT_2B)
			else:
				print("gnome told to tend not a seedling??")
				print(seedling_id)
			current_gnome.set_state(GNOME_STATE.IDLE)
			update_garden_score()
			print("gnome set to idle after tending plant")
		
		GNOME_STATE.HARVESTING:
			current_level.erase_cell(FOREGROUND, map_pos)
			current_level.erase_cell(HARVEST_SELECTION, map_pos)
			current_level.set_cell(BACKGROUND, map_pos, TILEMAP_SOURCE_ID, PASSABLE_DIRT_ATLAS_COORDS)
			flowersPos.erase(map_pos)
			update_flower_count()
			update_garden_score()
			harvestablePos.erase(map_pos)
			current_gnome.set_state(GNOME_STATE.HAULING)
			print("gnome set to hauling after harvesting")

#updates the hud messages and displays them
func update_hud_messages(messages):
	hud.update_message_list(messages)
	hud.show_message_text()

# Updates the contents of the flower_count variable and pushes it to the hud
func update_flower_count():
	flower_count = flowersPos.size()
	hud.update_flower_counter(flower_count)
	
	var number_of_gnomes = gnomes.size()
	if number_of_gnomes < float(flower_count) / 5:
		spawn_gnome()

# Adds plant coords to the tending array
func _on_plant_needs_tending(pos: Vector2):
	var map_pos = current_level.local_to_map(pos)
	seedlingPos.push_back(map_pos)
	flowersPos.push_back(map_pos)
	update_flower_count()
	print("plant added to tending queue")

#Adds plant coords to harvestable array
func _on_plant_finished_growing(pos: Vector2):
	var map_pos = current_level.local_to_map(pos)
	harvestablePos.push_back(map_pos)
	print("plant added to harvest queue")

# Calculates the garden score and updates the HUD
func update_garden_score():
	var rocks = current_level.get_used_cells_by_id(FOREGROUND, TILEMAP_SOURCE_ID, ROCK_ATLAS_COORDS)
	var flower_ones = current_level.get_used_cells_by_id(FOREGROUND, PLANT_TILEMAP_SOURCE_ID, PLANT_ATLAS, PLANT_1B)
	var flower_twos = current_level.get_used_cells_by_id(FOREGROUND, PLANT_TILEMAP_SOURCE_ID, PLANT_ATLAS, PLANT_2B)
	
	var score = (rocks.size() * -2) + (flower_ones.size() * 1) + (flower_twos.size() * 5)
	hud.update_garden_score(score)
