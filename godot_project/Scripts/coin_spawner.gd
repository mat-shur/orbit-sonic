extends Timer

@export var coin_scene : PackedScene
@export var spawn_distance : float = 350.0
@export var min_x : float = -400
@export var max_x : float = 400
@export var spawn_interval : float = 1.0
@export var height : float = 1200

@onready var player : Node2D = $"../Player/Player"
var last_spawn_y : float = 0.0


func _on_timeout() -> void:
	if player.global_position.y < last_spawn_y - spawn_distance:
		var try = randi_range(0, 4)
		
		if try == 0:
			_spawn_coin()
		
		last_spawn_y = player.position.y


func _spawn_coin():
	var pattern = randi() % 30
	var pos_x = player.global_position.x + randf_range(min_x, max_x)


	match pattern:
		0:
			for i in range(4):
				var coin = coin_scene.instantiate()
				coin.global_position = Vector2(pos_x + i * 45, player.global_position.y - height)
				$"../Comets".add_child(coin)
		1:
			for i in range(5):
				var coin = coin_scene.instantiate()
				coin.global_position = Vector2(pos_x + i * 100, player.global_position.y - height + i * 90)
				$"../Comets".add_child(coin)
		2:
			for i in range(6):
				var coin = coin_scene.instantiate()
				var x_offset = (sin(i * 0.5) * 100)
				coin.global_position = Vector2(pos_x + x_offset, player.global_position.y - height - i * 80)
				$"../Comets".add_child(coin)
		3:
			var radius = 200
			for i in range(12):
				var coin = coin_scene.instantiate()
				var angle = deg_to_rad(i * 30)
				var x_pos = pos_x + cos(angle) * radius
				var y_pos = player.global_position.y - height - sin(angle) * radius
				coin.global_position = Vector2(x_pos, y_pos)
				$"../Comets".add_child(coin)
		4:
			var base_size = 5
			for i in range(base_size):
				for j in range(i + 1):
					var coin = coin_scene.instantiate()
					var x_pos = pos_x + (j * 40) - (i * 20)
					var y_pos = player.global_position.y - height - (i * 40)
					coin.global_position = Vector2(x_pos, y_pos)
					$"../Comets".add_child(coin)
		5:
			var square_size = 4
			for i in range(square_size):
				for j in range(square_size):
					var coin = coin_scene.instantiate()
					var x_pos = pos_x + (j * 50)
					var y_pos = player.global_position.y - height - (i * 50)
					coin.global_position = Vector2(x_pos, y_pos)
					$"../Comets".add_child(coin)
		6:
			var center = player.global_position.y - height - 100
			var num_rays = 8
			var coins_per_ray = 3
			var ray_length = 150
			var angle_between_rays = PI / num_rays
			
			for ray in range(num_rays):
				var angle = ray * 2 * angle_between_rays
				for i in range(coins_per_ray):
					var coin = coin_scene.instantiate()
					
					var x_offset = cos(angle) * ray_length * (i / float(coins_per_ray))
					var y_offset = sin(angle) * ray_length * (i / float(coins_per_ray))
					coin.global_position = Vector2(pos_x + x_offset, center + y_offset)
					
					$"../Comets".add_child(coin)
		_:
			var coin = coin_scene.instantiate()
			coin.global_position = Vector2(pos_x, player.global_position.y - height)
			$"../Comets".add_child(coin)
