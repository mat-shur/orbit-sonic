extends Node2D

var satellites_preload = preload("res://Scenes/satellite.tscn")
@export var belt_width : float = 10000.0
@export var belt_height : float = 6500.0
@export var hex_size : float = 1500.0
@export var spawn_chance : float = 1
@export var objects_per_frame : int = 1 

var player : Node2D = null
var spawn_queue = []
var is_spawning = false

func _ready():
	calculate_spawn_positions()
	start_spawning()

func calculate_spawn_positions():
	var hex_width = sqrt(3) * hex_size
	var hex_height = 2 * hex_size
	var horizontal_spacing = hex_width
	var vertical_spacing = hex_height * 3/4
	var num_cols = int(belt_width / horizontal_spacing) + 1
	var num_rows = int(belt_height / vertical_spacing) + 1
	
	for col in range(num_cols):
		for row in range(num_rows):
			if randf() < spawn_chance:
				var x = col * horizontal_spacing + (row % 2) * (horizontal_spacing / 2) - belt_width / 2
				var y = row * vertical_spacing - belt_height
				var random_offset_x = randf_range(-hex_size * 0.25, hex_size * 0.25)
				var random_offset_y = randf_range(-hex_size * 0.25, hex_size * 0.25)
				var satellite_position = Vector2(x + random_offset_x, y + random_offset_y)
				spawn_queue.append(satellite_position)

func start_spawning():
	is_spawning = true
	set_process(true)

func _process(_delta):
	if is_spawning:
		for i in range(min(objects_per_frame, spawn_queue.size())):
			if spawn_queue.is_empty():
				is_spawning = false
				set_process(false)
				break
			var pos = spawn_queue.pop_front()
			spawn_planet(pos)

func spawn_planet(satellite_position : Vector2):
	var scene = satellites_preload
	var satellites = scene.instantiate()
	
	satellites.global_position = satellite_position
	satellites.player = player
	
	add_child(satellites)
