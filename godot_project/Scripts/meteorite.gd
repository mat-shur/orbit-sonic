extends Area2D

@export var speed : float = 150.0
@export var hide_distance : float = 2500.0

var rotation_speed: float = 0.0
var direction : Vector2 = Vector2.ZERO
var player : Node2D = null

func _ready() -> void:
	var rand = randf_range(1.4, 1.8)
	scale = Vector2(rand, rand)
	rotation_speed = randf_range(-0.5, 0.5)

func _process(delta: float) -> void:
	rotation += delta * rotation_speed
	position += direction * speed * delta
	
	if player:
		update_visibility()

func update_visibility():
	var distance_to_player = global_position.distance_to(player.position)

	if distance_to_player > hide_distance:
		if $Sprite2D.visible:
			$Sprite2D.visible = false
			$CollisionPolygon2D.disabled = true
	else:
		if not $Sprite2D.visible:
			$Sprite2D.visible = true
			$CollisionPolygon2D.disabled = false
