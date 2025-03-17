extends Node2D

var planet_preload = preload("res://Scenes/planet.tscn")
var comet_preload = preload("res://Scenes/comet.tscn")

@export var belt_width : float = 7500.0
@export var belt_height : float = 7500.0
@export var grid_size : float = 1350.0
@export var spawn_chance : float = 0.4

@export var comet_spawn_height : float = 1300

var player : Node2D = null


func _ready():
	spawn_planets_on_grid()


func spawn_planets_on_grid():
	var num_cells_x = int(belt_width / grid_size)
	var num_cells_y = int(belt_height / grid_size)
	
	for x in range(num_cells_x):
		for y in range(num_cells_y):
			if randf() < spawn_chance:
				var random_offset_x = randf_range(-grid_size * 0.4, grid_size * 0.4)
				var random_offset_y = randf_range(-grid_size * 0.4, grid_size * 0.4)
				
				var planet_position = Vector2(
					x * grid_size - belt_width / 2 + random_offset_x,
					y * grid_size - belt_height + random_offset_y
				)
				
				spawn_planet(planet_position)


func spawn_planet(meteorite_position : Vector2):
	var scene = planet_preload
	var planet = scene.instantiate()
	
	var size_of_planet = randf_range(0.4, 0.8)
	
	planet.global_position = meteorite_position
	planet.scale = Vector2(size_of_planet, size_of_planet)
	
	planet.add_to_group("meteorite")
	add_child(planet)


func _on_comet_spawner_timeout() -> void:
	if player.global_position.y < global_position.y + 250 and player.global_position.y > global_position.y - belt_height:
		var spawn_x = randf_range(-600, +600)
		var spawn_position = Vector2(player.global_position.x + spawn_x, player.global_position.y - comet_spawn_height)
		spawn_rocket(spawn_position)


func spawn_rocket(spawn_position):
	var comet = comet_preload.instantiate()
	comet.global_position = spawn_position
	comet.add_to_group("meteorite")
	get_parent().add_child(comet)
