extends Node2D

var gnome = preload("res://scenes/gnome.tscn")

@onready var tutorial_level = $TutorialLevel
@onready var hud = $HUD

#tile map shortcuts
var tilemap_source_id = 0
var plant_tilemap_source_id = 1
var background = 0
var permanents = 1
var foreground = 2
var clearSelection = 3
var plantSelection = 4
var harvestSelection = 5

#tile id shortcuts
var highlight_atlas_coords = Vector2i(12,0)
var passable_dirt_atlas_coords = Vector2i(7,0)
var impassable_dirt_atlas_coords = Vector2i(6,0)
var rock_atlas_coords = Vector2i(10, 0)
var plant_id = Vector2i(0, 0)
var plant_1 = 0
var plant_2 = 1

#color shortcuts
var clearHighlightColor = Color(0,0,0.5,0.5)
var plantHighlightColor = Color(0,0.5,0,0.5)
var removeColor = Color(1,1,1,1)
var highlightColor = Color(1,1,1,0.4)
var removeHighlightColor = Color(1,1,1,0)

# object tracking
var gnomes = []
var clearDebrisPos = []
var plantSeedPos = []
var seedlingPos = []
var flowersPos = []
var harvestablePos = []
var harvestPos = []

# score keeping
var flower_count = flowersPos.size()
var fruit_count = 0

# state tracking
enum MODES {NULL, CLEAR_DEBRIS, PLANT, HARVEST}
var mode = MODES.NULL
# THIS ENUM MUST MATCH THE ONE IN GNOME.GD IDENTICALLY
enum GNOME_STATE {IDLE, CLEARING_DEBRIS, PLANTING_SEED, TENDING_PLANT, HARVESTING, HAULING}

# Called when the node enters the scene tree for the first time.
func _ready():
	register_buttons()
	spawn_gnome()
	initial_hud_messages()
	update_garden_score()
	

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
func register_gnome_signals(current_gnome):
	current_gnome.connect("idle", _on_gnome_idle)
	current_gnome.connect("arrived", _on_gnome_arrived)
	current_gnome.connect("gnome_finished_busy_animation", _on_gnome_finished_busy_animation)

# Opening game messages
func initial_hud_messages():
	hud.update_message_list("Welcome to Gnome Garden!")
	hud.update_message_list("Click the Plant Seed button to get started.")
	hud.show_message_text()

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
		
		MODES.HARVEST:
			#left click in HARVEST MODE
			if event.is_action_pressed("click"):
				if harvestablePos.find(tile_mouse_pos) != -1:
					tutorial_level.set_cell(harvestSelection, tile_mouse_pos, tilemap_source_id, highlight_atlas_coords)
					harvestPos.push_back(tile_mouse_pos)
			#right click in HARVEST MODE
			if event.is_action_pressed("right click"):
				tutorial_level.erase_cell(harvestSelection, tile_mouse_pos)
				harvestPos.erase(tile_mouse_pos)

		_:
			pass

#Sets the player's game mode
func set_mode(_mode):
	mode = _mode
	
	match mode:
		MODES.NULL:
			tutorial_level.set_layer_modulate(clearSelection, removeHighlightColor)
			tutorial_level.set_layer_modulate(plantSelection, removeHighlightColor)
			tutorial_level.set_layer_modulate(harvestSelection, removeHighlightColor)
			tutorial_level.set_layer_modulate(background, removeColor)
			
		MODES.CLEAR_DEBRIS:
			tutorial_level.set_layer_modulate(clearSelection, highlightColor)
			tutorial_level.set_layer_modulate(background, clearHighlightColor)
			
		MODES.PLANT:
			tutorial_level.set_layer_modulate(plantSelection, highlightColor)
			tutorial_level.set_layer_modulate(background, plantHighlightColor)
		
		MODES.HARVEST:
			tutorial_level.set_layer_modulate(background, plantHighlightColor)
			tutorial_level.set_layer_modulate(harvestSelection, highlightColor)

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
		pos = tutorial_level.map_to_local(seedlingPos.pop_front())
		job = GNOME_STATE.TENDING_PLANT
		print("gnome told to tend")
	
	elif not harvestPos.is_empty():
		pos = tutorial_level.map_to_local(harvestPos.pop_front())
		job = GNOME_STATE.HARVESTING
		print("gnome told to harvest")
		
	elif not clearDebrisPos.is_empty():
		pos = tutorial_level.map_to_local(clearDebrisPos.pop_front())
		job = GNOME_STATE.CLEARING_DEBRIS
		print("gnome told to clear debris")
		
	elif not plantSeedPos.is_empty():
		pos = tutorial_level.map_to_local(plantSeedPos.pop_front())
		job = GNOME_STATE.PLANTING_SEED
		print("gnome told to plant seed")
		
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
	var map_pos = tutorial_level.local_to_map(pos)
	var foreground_cells = tutorial_level.get_used_cells(foreground)
	var permanent_cells = tutorial_level.get_used_cells(permanents)
	
	match job:
		GNOME_STATE.IDLE:
			current_gnome.set_state(job)
		
		GNOME_STATE.CLEARING_DEBRIS:
			if not reachable:
				tutorial_level.erase_cell(clearSelection, map_pos)
				current_gnome.set_state(GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
			
			elif foreground_cells.find(map_pos) != -1:
				print("gnome told to clear")
				tutorial_level.erase_cell(clearSelection, map_pos)
				current_gnome.set_state(job)
			
			else:
				print("gnome state set to idle on arrival because foreground cell is empty")
				tutorial_level.erase_cell(clearSelection, map_pos)
				current_gnome.set_state(GNOME_STATE.IDLE)
			
		GNOME_STATE.PLANTING_SEED:
			if not reachable:
				tutorial_level.erase_cell(plantSelection, map_pos)
				current_gnome.set_state(GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
				
			elif foreground_cells.find(map_pos) != -1 or permanent_cells.find(map_pos) != -1:
				print("gnome won't plant here because foreground cell is occupied")
				tutorial_level.erase_cell(plantSelection, map_pos)
				current_gnome.set_state(GNOME_STATE.IDLE)
					
			else:
				print("gnome told to plant seed upon arrival")
				tutorial_level.erase_cell(plantSelection, map_pos)
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

# Updates the tilemap based on what the gnome was just doing
# Sets the gnome back to idle now that he's done his job
func _on_gnome_finished_busy_animation(job, pos, current_gnome):
	print("busy animation finished")
	var map_pos = tutorial_level.local_to_map(pos)
	match job:
		GNOME_STATE.IDLE:
			print("busy while idle??")
			
		GNOME_STATE.CLEARING_DEBRIS:
			tutorial_level.erase_cell(foreground, map_pos)
			tutorial_level.set_cell(background, map_pos, tilemap_source_id, passable_dirt_atlas_coords)
	
			if flowersPos.find(map_pos) != -1:
				flowersPos.erase(map_pos)
				update_flower_count()
				
			update_garden_score()
			current_gnome.set_state(GNOME_STATE.IDLE)
			print("gnome set to idle after clearing debris")
			
		GNOME_STATE.PLANTING_SEED:
			tutorial_level.set_cell(background, map_pos, tilemap_source_id, impassable_dirt_atlas_coords)
			tutorial_level.set_cell(foreground, map_pos, plant_tilemap_source_id, plant_id, plant_1)
			current_gnome.set_state(GNOME_STATE.IDLE)
			print("gnome set to idle after planting seed")
		
		GNOME_STATE.TENDING_PLANT:
			tutorial_level.set_cell(foreground, map_pos, plant_tilemap_source_id, plant_id, plant_2)
			current_gnome.set_state(GNOME_STATE.IDLE)
			print("gnome set to idle after tending plant")
		
		GNOME_STATE.HARVESTING:
			tutorial_level.erase_cell(foreground, map_pos)
			tutorial_level.erase_cell(harvestSelection, map_pos)
			tutorial_level.set_cell(background, map_pos, tilemap_source_id, passable_dirt_atlas_coords)
			flowersPos.erase(map_pos)
			update_flower_count()
			harvestablePos.erase(map_pos)
			current_gnome.set_state(GNOME_STATE.HAULING)
			print("gnome set to hauling after harvesting")

# Updates the contents of the flower_count variable and pushes it to the hud
func update_flower_count():
	flower_count = flowersPos.size()
	hud.update_flower_counter(flower_count)
	update_garden_score()
	
	var number_of_gnomes = gnomes.size()
	if number_of_gnomes < float(flower_count) / 5:
		spawn_gnome()

# Adds plant coords to the tending array
func _on_plant_needs_tending(pos: Vector2):
	var map_pos = tutorial_level.local_to_map(pos)
	seedlingPos.push_back(map_pos)
	flowersPos.push_back(map_pos)
	update_flower_count()
	print("plant added to tending queue")

#Adds plant coords to harvestable array
func _on_plant_finished_growing(pos: Vector2):
	var map_pos = tutorial_level.local_to_map(pos)
	harvestablePos.push_back(map_pos)
	print("plant added to harvest queue")

func update_garden_score():
	var foreground_cells = tutorial_level.get_used_cells_by_id(foreground, tilemap_source_id, rock_atlas_coords)
	var score = (foreground_cells.size() * -2) + (flower_count)
	hud.update_garden_score(score)
