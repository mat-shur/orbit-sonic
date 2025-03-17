extends Area2D

var player: Node2D
var color_rect: ColorRect
var collision_shape: CollisionShape2D
var line_width = 1000
var line_length = 5000
var base_speed = 300
var catch_up_speed = 3500  
var max_distance = 2000


@onready var map = $"../"


func _ready():
	color_rect = ColorRect.new()
	color_rect.color = Color.WHITE
	color_rect.color.a = 0.5
	color_rect.size = Vector2(line_length, line_width)
	color_rect.position.y = -line_width / 2.0
	color_rect.position.x = -line_length / 2.0
	add_child(color_rect)
	
	collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(line_length, line_width)
	collision_shape.shape = shape
	add_child(collision_shape)
	
	player = get_node("../Player/Player") 
	
	connect("area_entered", Callable(self, "on_area_entered"))

func _process(delta):
	if map.started:
		if player:
			global_position.x = player.global_position.x
			
			var speed = base_speed
			var distance_to_player = global_position.y - player.global_position.y
			
			if distance_to_player > max_distance:
				speed = catch_up_speed
			
			global_position.y -= speed * delta 

func on_area_entered(area):
	if area == player:
		print("Die!")
