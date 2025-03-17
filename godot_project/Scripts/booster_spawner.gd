extends Timer

@export var star_scene : PackedScene
@export var spawn_distance : float = 500.0
@export var min_x : float = -400
@export var max_x : float = 400
@export var spawn_interval : float = 1.0
@export var height : float = 1200

@onready var player : Node2D = $"../Player/Player"
var last_spawn_y : float = 0.0
var count_chance = 25

var type;


func _ready() -> void:
	type = get_parent().get_node("PlayerData").type_rocket
	
	if type == "RKT-2" or type == "RKT-SR":
		count_chance = 7
		


func _on_timeout() -> void:
	if player.global_position.y < last_spawn_y - spawn_distance:
		var try = randi_range(0, count_chance)
		
		if try == 0:
			_spawn_star()
		
		last_spawn_y = player.position.y


func _spawn_star():
	var pos_x = player.global_position.x + randf_range(min_x, max_x)
	var coin = star_scene.instantiate()
	coin.global_position = Vector2(pos_x, player.global_position.y - height)
	$"../Comets".add_child(coin)
