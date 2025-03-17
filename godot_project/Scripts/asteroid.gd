extends Node2D

@export var speed : float = 425.0
var direction : Vector2 = Vector2.ZERO
var rotation_speed: float = 0.0
var player : Node2D = null


func _ready() -> void:
	if randf() < 0.5:
		rotation_speed = randf_range(-2.5, -1.5)
	else:
		rotation_speed = randf_range(2.5, 1.5)
	
	var scale_r = randf_range(1, 1.6)
	scale = Vector2(scale_r, scale_r)

func _process(delta):
	if direction != Vector2.ZERO:
		rotation += delta * rotation_speed
		position += direction * speed * delta
		
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance > 3500:
			queue_free()
