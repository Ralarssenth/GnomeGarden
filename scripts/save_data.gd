class_name SaveGame
extends Resource

const SAVE_GAME_PATH = "user://savegame.tres"
const LEVEL_SAVE_PATH = "user://level_savegame.tscn"

@export var level_tilemap : PackedScene
@export var days : int 

@export var clearDebrisPos: Array[Vector2i] = []

# score keeping
@export var flower_count : int
@export var fruit_count : int
@export var biodiversity : int

func update_save_data(_level):
	level_tilemap = _level
	
func write_savegame():
	ResourceSaver.save(self, SAVE_GAME_PATH)
	ResourceSaver.save(level_tilemap, LEVEL_SAVE_PATH)

func load_savegame():
	if ResourceLoader.exists(LEVEL_SAVE_PATH):
		level_tilemap = ResourceLoader.load(LEVEL_SAVE_PATH)
	else:
		level_tilemap = PackedScene.new()
	if ResourceLoader.exists(SAVE_GAME_PATH):
		return ResourceLoader.load(SAVE_GAME_PATH)
	return null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
