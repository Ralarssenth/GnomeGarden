extends Node2D

var gnome = preload("res://scenes/gnome.tscn")
var tutorial_level = preload("res://scenes/tutorial_level.tscn")
var sandbox_level = preload("res://scenes/sandbox.tscn")

@onready var camera = $Camera2D
@onready var hud = $HUD

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
var harvestablePos = []
var harvestPos = []

# score keeping
var flower_count = 0
var fruit_count = 0
var biodiversity = 1

# Day tracking
@onready var day_timer = $DayTimer
var day_tracker = 0

# state tracking
enum MODES {NULL, CLEAR_DEBRIS, PLANT, PLANT2, HARVEST, DRAG}
var mode = MODES.NULL


# Called when the node enters the scene tree for the first time.
func _ready():
	register_buttons()
	hud.show_menu_hud()
	

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
	start_days()
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
			"SandboxLevel":
				start_level(sandbox_level)

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
					current_level.set_cell(
						current_level.CLEAR_SELECTION, 
						tile_mouse_pos, 
						current_level.TILEMAP_SOURCE_ID, 
						current_level.HIGHLIGHT_ATLAS_COORDS
					)
					clearDebrisPos.push_back(tile_mouse_pos)
					print("appended clear debris array")
					
				#right click in CLEAR MODE
				if event.is_action_pressed("right click"):
					current_level.erase_cell(current_level.CLEAR_SELECTION, tile_mouse_pos)
					clearDebrisPos.erase(tile_mouse_pos)
					print("erased a position from the clear debris array")
				
			MODES.PLANT:
				#left click in PLANT MODE
				if event.is_action_pressed("click"):
						current_level.set_cell(
							current_level.PLANT_SELECTION, 
							tile_mouse_pos, 
							current_level.TILEMAP_SOURCE_ID, 
							current_level.HIGHLIGHT_ATLAS_COORDS
						)
						plantSeedPos.push_back(tile_mouse_pos)
						print("appended plant seed array")
				
				#right click in PLANT MODE
				if event.is_action_pressed("right click"):
					current_level.erase_cell(current_level.PLANT_SELECTION, tile_mouse_pos)
					plantSeedPos.erase(tile_mouse_pos)
			
			MODES.PLANT2:
				if event.is_action_pressed("click"):
						current_level.set_cell(
							current_level.PLANT_SELECTION, 
							tile_mouse_pos, 
							current_level.TILEMAP_SOURCE_ID, 
							current_level.HIGHLIGHT_ATLAS_COORDS
						)
						plantSeed2Pos.push_back(tile_mouse_pos)
						print("appended plant seed array")
				#right click in PLANT MODE
				if event.is_action_pressed("right click"):
					current_level.erase_cell(current_level.PLANT_SELECTION, tile_mouse_pos)
					plantSeedPos.erase(tile_mouse_pos)
			
			MODES.HARVEST:
				#left click in HARVEST MODE
				if event.is_action_pressed("click"):
					if harvestablePos.has(tile_mouse_pos):
						current_level.set_cell(
							current_level.HARVEST_SELECTION, 
							tile_mouse_pos, 
							current_level.TILEMAP_SOURCE_ID, 
							current_level.HIGHLIGHT_ATLAS_COORDS
						)
						harvestPos.push_back(tile_mouse_pos)
				#right click in HARVEST MODE
				if event.is_action_pressed("right click"):
					current_level.erase_cell(current_level.HARVEST_SELECTION, tile_mouse_pos)
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
			current_level.set_layer_modulate(current_level.CLEAR_SELECTION, Globals.REMOVE_HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(current_level.PLANT_SELECTION, Globals.REMOVE_HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(current_level.HARVEST_SELECTION, Globals.REMOVE_HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(current_level.BACKGROUND, Globals.REMOVE_COLOR)
			
		MODES.CLEAR_DEBRIS:
			current_level.set_layer_modulate(current_level.CLEAR_SELECTION, Globals.HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(current_level.BACKGROUND, Globals.CLEAR_HIGHLIGHT_COLOR)
			
		MODES.PLANT:
			current_level.set_layer_modulate(current_level.PLANT_SELECTION, Globals.HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(current_level.BACKGROUND, Globals.PLANT_HIGHLIGHT_COLOR)
		
		MODES.PLANT2:
			current_level.set_layer_modulate(current_level.PLANT_SELECTION, Globals.HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(current_level.BACKGROUND, Globals.PLANT_HIGHLIGHT_COLOR)
		
		MODES.HARVEST:
			current_level.set_layer_modulate(current_level.BACKGROUND, Globals.PLANT_HIGHLIGHT_COLOR)
			current_level.set_layer_modulate(current_level.HARVEST_SELECTION, Globals.HIGHLIGHT_COLOR)

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
		job = Globals.GNOME_STATE.TENDING_PLANT
		print("gnome told to tend")
	
	elif not harvestPos.is_empty():
		pos = current_level.map_to_local(harvestPos.pop_front())
		job = Globals.GNOME_STATE.HARVESTING
		print("gnome told to harvest")
		
	elif not clearDebrisPos.is_empty():
		pos = current_level.map_to_local(clearDebrisPos.pop_front())
		job = Globals.GNOME_STATE.CLEARING_DEBRIS
		print("gnome told to clear debris")
		
	elif not plantSeedPos.is_empty():
		pos = current_level.map_to_local(plantSeedPos.pop_front())
		job = Globals.GNOME_STATE.PLANTING_SEED
		print("gnome told to plant seed")
		
	elif not plantSeed2Pos.is_empty():
		pos = current_level.map_to_local(plantSeed2Pos.pop_front())
		job = Globals.GNOME_STATE.PLANTING_SEED2
		print("gnome told to plant seed2")
		
	else:
		# pick a random spot on the map
		pos = Vector2(randf_range(-32.0, 32.0),randf_range(-32.0, 32.0))
		job = Globals.GNOME_STATE.IDLE
		print("gnome told to idle")

	current_gnome.set_movement_target(pos)
	current_gnome.set_job(job)
	print("gnome sent new position data")

# Tells a gnome what to do with a cell once they arrive 
# based on their assigned job and if they were able to reach their destination
func _on_gnome_arrived(pos: Vector2, job, reachable, current_gnome):
	print("gnome has arrived")
	var map_pos = current_level.local_to_map(pos)
	var foreground_cells = current_level.get_used_cells(current_level.FOREGROUND)
	var permanent_cells = current_level.get_used_cells(current_level.PERMANENTS)
	
	match job:
		Globals.GNOME_STATE.IDLE:
			current_gnome.set_state(job)
		
		Globals.GNOME_STATE.CLEARING_DEBRIS:
			if not reachable:
				current_level.erase_cell(current_level.CLEAR_SELECTION, map_pos)
				current_gnome.set_state(Globals.GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
			
			elif foreground_cells.find(map_pos) != -1:
				print("gnome told to clear")
				current_level.erase_cell(current_level.CLEAR_SELECTION, map_pos)
				current_gnome.set_state(job)
			
			else:
				print("gnome state set to idle on arrival because foreground cell is empty")
				current_level.erase_cell(current_level.CLEAR_SELECTION, map_pos)
				current_gnome.set_state(Globals.GNOME_STATE.IDLE)
			
		Globals.GNOME_STATE.PLANTING_SEED, Globals.GNOME_STATE.PLANTING_SEED2:
			if not reachable:
				current_level.erase_cell(current_level.PLANT_SELECTION, map_pos)
				current_gnome.set_state(Globals.GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
				
			elif foreground_cells.find(map_pos) != -1 or permanent_cells.find(map_pos) != -1:
				print("gnome won't plant here because foreground cell is occupied")
				current_level.erase_cell(current_level.PLANT_SELECTION, map_pos)
				current_gnome.set_state(Globals.GNOME_STATE.IDLE)
					
			else:
				print("gnome told to plant seed upon arrival")
				current_level.erase_cell(current_level.PLANT_SELECTION, map_pos)
				current_gnome.set_state(job)
		
		Globals.GNOME_STATE.TENDING_PLANT:
			if not reachable:
				current_gnome.set_state(Globals.GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
			
			else:
				current_gnome.set_state(job)
		
		Globals.GNOME_STATE.HARVESTING:
			if not reachable:
				current_gnome.set_state(Globals.GNOME_STATE.IDLE)
				print("gnome told to idle because cell unreachable")
			#todo: add a check for if harvestable
			else:
				current_gnome.set_state(job)
		
		Globals.GNOME_STATE.HAULING:
			fruit_count = fruit_count + 1
			hud.update_fruit_counter(fruit_count)
			current_gnome.set_state(Globals.GNOME_STATE.IDLE)
			hud.update_plant_button_visibility(fruit_count)

# Updates the tilemap based on what the gnome was just doing
# Sets the gnome back to idle now that he's done his job
func _on_gnome_finished_busy_animation(job, pos, current_gnome):
	print("busy animation finished")
	var map_pos = current_level.local_to_map(pos)
	match job:
		Globals.GNOME_STATE.IDLE:
			print("busy while idle??")
			
		Globals.GNOME_STATE.CLEARING_DEBRIS:
			current_level.erase_cell(current_level.FOREGROUND, map_pos)
			current_level.set_cell(
				current_level.BACKGROUND, 
				map_pos, 
				current_level.TILEMAP_SOURCE_ID, 
				current_level.DIRT1_ATLAS_COORDS
			)
			update_flower_count()
			update_garden_score()
			current_gnome.set_state(Globals.GNOME_STATE.IDLE)
			print("gnome set to idle after clearing debris")
			
		Globals.GNOME_STATE.PLANTING_SEED:
			current_level.set_cell(
				current_level.BACKGROUND, 
				map_pos, 
				current_level.TILEMAP_SOURCE_ID, 
				current_level.IMPASSABLE_DIRT_ATLAS_COORDS
			)
			current_level.set_cell(
				current_level.FOREGROUND, 
				map_pos, 
				current_level.TILEMAP_SOURCE_ID,  
				current_level.PLANT_1[0]
			)
			current_gnome.set_state(Globals.GNOME_STATE.IDLE)
			print("gnome set to idle after planting seed")
			start_grow_timer(map_pos, current_level.PLANT_1_GROW_TIME)

		
		Globals.GNOME_STATE.PLANTING_SEED2:
			current_level.set_cell(
				current_level.BACKGROUND, 
				map_pos, 
				current_level.TILEMAP_SOURCE_ID, 
				current_level.IMPASSABLE_DIRT_ATLAS_COORDS
			)
			current_level.set_cell(
				current_level.FOREGROUND, 
				map_pos, 
				current_level.TILEMAP_SOURCE_ID,  
				current_level.PLANT_2[0]
			)
			current_gnome.set_state(Globals.GNOME_STATE.IDLE)
			start_grow_timer(map_pos, current_level.PLANT_2_GROW_TIME)
			print("gnome set to idle after planting seed2")
		
		Globals.GNOME_STATE.TENDING_PLANT:
			var seedling_id = current_level.get_cell_atlas_coords(current_level.FOREGROUND, map_pos)
			if current_level.PLANT_1.has(seedling_id):
				var i = current_level.PLANT_1.find(seedling_id)
				current_level.set_cell(
				current_level.FOREGROUND, 
				map_pos, 
				current_level.TILEMAP_SOURCE_ID, 
				current_level.PLANT_1[(i + 1)]
				)
				if seedling_id == current_level.PLANT_1[-2]:
					start_harvest_timer(map_pos, current_level.PLANT_1_GROW_TIME)
				else:
					start_grow_timer(map_pos, current_level.PLANT_1_GROW_TIME)
					
			if current_level.PLANT_2.has(seedling_id):
				var i = current_level.PLANT_2.find(seedling_id)
				current_level.set_cell(
				current_level.FOREGROUND, 
				map_pos, 
				current_level.TILEMAP_SOURCE_ID,  
				current_level.PLANT_2[(i + 1)]
				)
				if seedling_id == current_level.PLANT_2[-2]:
					start_harvest_timer(map_pos, current_level.PLANT_2_GROW_TIME)
				else:
					start_grow_timer(map_pos, current_level.PLANT_2_GROW_TIME)
			
			current_gnome.set_state(Globals.GNOME_STATE.IDLE)
			update_flower_count()
			update_garden_score()
			print("gnome set to idle after tending plant")
		
		Globals.GNOME_STATE.HARVESTING:
			current_level.erase_cell(current_level.FOREGROUND, map_pos)
			current_level.erase_cell(current_level.HARVEST_SELECTION, map_pos)
			current_level.set_cell(
				current_level.BACKGROUND, 
				map_pos, 
				current_level.TILEMAP_SOURCE_ID, 
				current_level.DIRT1_ATLAS_COORDS
			)
			update_flower_count()
			update_garden_score()
			harvestablePos.erase(map_pos)
			current_gnome.set_state(Globals.GNOME_STATE.HAULING)
			print("gnome set to hauling after harvesting")

#updates the hud messages and displays them
func update_hud_messages(messages):
	hud.update_message_list(messages)
	hud.show_message_text()

# Updates the contents of the flower_count variable and pushes it to the hud
func update_flower_count():
	flower_count =  current_level.get_flowers()
	hud.update_flower_counter(flower_count)
	
	var number_of_gnomes = gnomes.size()
	if number_of_gnomes <= float(flower_count) / 5:
		spawn_gnome()

func start_grow_timer(pos, time):
	await get_tree().create_timer(time).timeout
	_on_plant_needs_tending(pos)

func start_harvest_timer(pos, time):
	await get_tree().create_timer(time).timeout
	_on_plant_finished_growing(pos)

# Adds plant coords to the tending array
func _on_plant_needs_tending(map_pos):
	seedlingPos.push_back(map_pos)
	print("plant added to tending queue" + str(map_pos))

#Adds plant coords to harvestable array
func _on_plant_finished_growing(map_pos):
	harvestablePos.push_back(map_pos)
	print("plant added to harvest queue" + str(map_pos))

# Starts the day tracking based on the current_level
func start_days():
	if in_level:
		day_timer.set_wait_time(current_level.get_day_length())
		day_timer.start()
	
# Tracks the days elapsed and triggers game_over() based on the current_level
func _on_day_timer_timeout():
	if in_level:
		day_tracker += 1
		print("day timer incremented")
		hud.day.set_text(str(day_tracker))
		if current_level.get_game_mode() == Globals.GAME_MODES.STANDARD:
			if day_tracker >= current_level.get_days():
				game_over()

# Calculates the garden score and updates the HUD
func update_garden_score():
	var rocks = current_level.get_used_cells_by_id(
		current_level.FOREGROUND, 
		current_level.TILEMAP_SOURCE_ID, 
		current_level.ROCK_ATLAS_COORDS
	)
	
	biodiversity = current_level.get_biodiversity() 
	var score = (rocks.size() * -2) + (flower_count * biodiversity)
	hud.update_garden_score(score)
	print("garden score updated")


