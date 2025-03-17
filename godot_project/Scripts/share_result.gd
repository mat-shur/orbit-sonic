extends Button


var rotation_speed = 15.0
var max_rotation_angle = 3.0
var time_elapsed = 0.0


func _process(delta: float) -> void:
	time_elapsed += delta * rotation_speed
	var current_angle = max_rotation_angle * sin(time_elapsed)
	rotation_degrees = current_angle
	
