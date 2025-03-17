extends Node2D

var planet_preload = preload("res://Scenes/planet.tscn")
var asteroid_preload = preload("res://Scenes/asteroid.tscn")

@export var belt_width : float = 7500.0
@export var belt_height : float = 7500.0
@export var grid_size : float = 1350.0
@export var spawn_chance : float = 0.4

@export var comet_spawn_height : float = 1300
@export var asteroid_spawn_distance : float = 100.0
@export var asteroid_spawn_chance : float = 0.4 
@export var asteroid_speed : float = 420.0 
@export var base_target_offset_y : float = 1100 
@export var max_rotation : float = deg_to_rad(45) 

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
		var sides = ["top", "bottom", "left", "right"]
		var side = sides[randi() % sides.size()]
		
		var spawn_distance = 1200 
		var spawn_position = Vector2()
		var target_position = player.global_position 
		
		var player_rotation = player.rotation  
		
		player_rotation = clamp(player_rotation, -max_rotation, max_rotation)
		
		var rotation_factor = player_rotation / max_rotation 
		
		var offset_change = rotation_factor * base_target_offset_y  
		
		var final_target_offset_y = base_target_offset_y - offset_change  
		
		match side:
			"top":
				spawn_position.x = player.global_position.x + randf_range(-600, 600)
				spawn_position.y = player.global_position.y - spawn_distance
				target_position = player.global_position
			"left":
				spawn_position.x = player.global_position.x - spawn_distance
				spawn_position.y = player.global_position.y + randf_range(-600, 600)
				target_position = Vector2(player.global_position.x, player.global_position.y - final_target_offset_y)
			"right":
				spawn_position.x = player.global_position.x + spawn_distance
				spawn_position.y = player.global_position.y + randf_range(-600, 600)
				target_position = Vector2(player.global_position.x, player.global_position.y - final_target_offset_y)
		
		spawn_asteroid(spawn_position, target_position)


func spawn_asteroid(spawn_position: Vector2, target_position: Vector2):
	var asteroid = asteroid_preload.instantiate()
	asteroid.global_position = spawn_position
	asteroid.add_to_group("meteorite")
	
	var direction = (target_position - spawn_position).normalized()
	asteroid.direction = direction 
	asteroid.player = player
	
	get_parent().add_child(asteroid)
