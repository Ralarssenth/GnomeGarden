extends Node2D

@onready var tutorial_level = $TutorialLevel
@onready var gnome = $Gnome

var tilemap_source_id = 0
var background = 0
var foreground = 2
var clearSelection = 3
var plantSelection = 4
var seedling_atlas_coords = Vector2i(6, 9)
var highlight_atlas_coords = Vector2i(12,0)
var clearHighlightColor = Color(0,0,0.5,0.5)
var plantHighlightColor = Color(0,0.5,0,0.5)
var removeColor = Color(1,1,1,1)
var highlightColor = Color(1,1,1,0.4)
var removeHighlightColor = Color(1,1,1,0)

var clearDebrisPos = []
var plantSeedPos = []

enum MODES {NULL, CLEAR_DEBRIS, PLANT}
var mode = MODES.NULL


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

func register_gnome_signals():
	gnome.connect("idle", _on_gnome_idle)
	gnome.connect("arrived", _on_gnome_arrived)
	
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
	match  mode:
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
	if not clearDebrisPos.is_empty():
		pos = tutorial_level.map_to_local(clearDebrisPos.pop_front())
	elif not plantSeedPos.is_empty():
		pos = tutorial_level.map_to_local(plantSeedPos.pop_front())
	else:
		# currently hardcoded, should be call to wander randomly eventually
		pos = Vector2(0.0,0.0)
	select_movement_target(pos)
	print("gnome idle signal caught")

func _on_gnome_arrived(pos: Vector2):
	var map_pos = tutorial_level.local_to_map(pos)
	tutorial_level.erase_cell(clearSelection, map_pos)
	tutorial_level.erase_cell(plantSelection, map_pos)

func select_movement_target(pos: Vector2):
	gnome.set_movement_target(pos)
	print("gnome sent new position data")
