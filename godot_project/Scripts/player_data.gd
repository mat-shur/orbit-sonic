extends Node

var type_rocket: String = "Vessel 0"

var upg_speed: int = 0
var upg_rotation: int = 0
var upg_boost_duration: int = 0
var upg_boost_speed: int = 0

const SAVE_FILE_PATH: String = "user://save_game.cfg"


func _ready():
	load_game()


func save_game():
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_line(type_rocket)
		file.store_32(upg_speed)
		file.store_32(upg_rotation)
		file.store_32(upg_boost_duration)
		file.store_32(upg_boost_speed)
		file.close()
		print("Game data saved successfully.")
		print(type_rocket)
	else:
		print("Failed to open save file for writing.")

func load_game():
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		if file.get_length() >= 20: # 5 variables * 4 bytes each
			type_rocket = file.get_line()
			upg_speed = file.get_32()
			upg_rotation = file.get_32()
			upg_boost_duration = file.get_32()
			upg_boost_speed = file.get_32()
			print("Game data loaded successfully:")
			print("Type Rocket: %s" % type_rocket)
			print("Upgrade Speed: %d" % upg_speed)
			print("Upgrade Rotation: %d" % upg_rotation)
			print("Upgrade Boost Duration: %d" % upg_boost_duration)
			print("Upgrade Boost Speed: %d" % upg_boost_speed)
		else:
			print("Save file is too small. Using default values.")
		file.close()
	else:
		print("Save file not found. Using default values.")
