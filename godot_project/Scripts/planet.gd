extends Area2D

@export var gravitational_constant : float = 1000.0 
@export var planet_mass : float = 5000.0
@export var max_gravity_radius : float = 300.0
@export var min_gravity_radius : float = 50.0



func apply_gravity_to_body(body: Node2D, delta: float) -> void:
	var direction_to_planet = global_position - body.global_position
	var distance = direction_to_planet.length()

	if distance < max_gravity_radius and distance > min_gravity_radius:
		var force_magnitude = (gravitational_constant * planet_mass) / pow(distance, 2)
		var gravity_force = direction_to_planet.normalized() * force_magnitude
		
		body.velocity += gravity_force * delta


func _on_body_entered(body: Node2D) -> void:
	apply_gravity_to_body(body, 50)
