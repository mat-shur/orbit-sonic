extends Area2D

@export var orbit_radius: float
@export var orbital_speed: float
@export var clockwise: bool
@export var initial_angle: float
@export var parent_node: Node2D


func _process(delta):
	var orbit_center = parent_node.global_position
	var time = Time.get_ticks_msec() / 1000.0
	var angle = initial_angle + orbital_speed * time * int((clockwise if -1 else 1))
	var new_pos = Vector2(cos(angle), sin(angle)) * orbit_radius
	global_position = orbit_center + new_pos


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	set_process(true)
	$CollisionShape2D.disabled = false 


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	set_process(false)
	$CollisionShape2D.disabled = true  
