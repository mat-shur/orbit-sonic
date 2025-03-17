extends Node2D

const METEOR_SCENES = [
	preload("res://Scenes/Meteorites/meteorite_0.tscn"),
	preload("res://Scenes/Meteorites/meteorite_1.tscn"),
	preload("res://Scenes/Meteorites/meteorite_2.tscn"),
	preload("res://Scenes/Meteorites/meteorite_3.tscn"),
	preload("res://Scenes/Meteorites/meteorite_4.tscn"),
	preload("res://Scenes/Meteorites/meteorite_5.tscn"),
	preload("res://Scenes/Meteorites/meteorite_6.tscn"),
	preload("res://Scenes/Meteorites/meteorite_7.tscn"),
	preload("res://Scenes/Meteorites/meteorite_8.tscn"),
	preload("res://Scenes/Meteorites/meteorite_9.tscn")
]

@export var num_meteorites : int = 1200
@export var meteor_speed : float = 75.0
@export var belt_width : float = 7500.0
@export var belt_height : float = 3500.0
@export var grid_size : float = 300.0
@export var spawn_chance : float = 0.8

var meteorites : Array[Node2D] = []
var player : Node2D = null

func _ready():
	player = get_parent().get_parent().get_node("Player/Player")
	spawn_meteorites_in_grid()


func spawn_meteorites_in_grid():
	var num_cells_x = int(belt_width / grid_size)
	var num_cells_y = int(belt_height / grid_size)
	
	for x in range(num_cells_x):
		for y in range(num_cells_y):
			if randf() < spawn_chance:
				var random_offset_x = randf_range(-grid_size * 0.4, grid_size * 0.4)
				var random_offset_y = randf_range(-grid_size * 0.4, grid_size * 0.4)
				
				var meteorite_position = Vector2(
					 x * grid_size - belt_width / 2 + random_offset_x,
				 y * grid_size - belt_height + random_offset_y
				)
				
				spawn_meteorite(meteorite_position)

func spawn_meteorite(meteorite_position : Vector2):
	var scene = METEOR_SCENES[randi() % METEOR_SCENES.size()]
	var meteorite = scene.instantiate()
	
	meteorite.global_position = meteorite_position
	meteorite.direction = Vector2(1, 0) 
	meteorite.player = player
	
	add_child(meteorite)
	meteorites.append(meteorite)
