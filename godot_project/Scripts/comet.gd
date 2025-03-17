extends Area2D

@export var speed: float = 500.0

var velocity: Vector2 = Vector2.ZERO


func _process(delta):
	velocity.y = speed
	
	position += velocity * delta
