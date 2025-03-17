extends Area2D

@export var min_radius: float = 75.0
@export var max_radius: float = 1500.0
@export var min_orbital_speed: float = 0.2
@export var max_orbital_speed: float = 0.33
@export var satellite_chance: float = 0.75
@export var max_satellites: int = 10
@export var max_sub_satellites: int = 3
@export var orbit_grid_size: int = 24
@export var planet_texture: Texture2D
@export var satellite_with_moons_texture: Texture2D
@export var satellite_without_moons_texture: Texture2D
@export var planet_size: float = 450.0
@export var satellite_size: float = 200.0
@export var sub_satellite_size: float = 50.0
@export var visibility_threshold: float = 2500.0 

var satellites = []
var available_orbits = []
var player: Node2D 

class SatelliteData:
	var node: Area2D
	var parent_node: Area2D
	var orbit_radius: float
	var orbital_speed: float
	var clockwise: bool
	var initial_angle: float
	var current_angle: float 

func _ready():
	add_to_group("meteorite")
	initialize_orbits()
	create_celestial_body(self, planet_texture, planet_size, Color.WHITE)

	for child in get_children():
		if child is Sprite2D or child is CollisionShape2D:
			child.visible = true  
	for i in range(max_satellites):
		if randf() < satellite_chance:
			create_satellite()

func initialize_orbits():
	var min_distance = max(planet_size, satellite_size) * 0.6
	min_radius = max(min_radius, planet_size + min_distance)
	var orbit_step = (max_radius - min_radius) / (orbit_grid_size - 1)
	for i in range(orbit_grid_size):
		available_orbits.append(min_radius + i * orbit_step)

func create_celestial_body(parent, texture: Texture2D, desired_size: float, modulate_color = Color.WHITE):
	var sprite = Sprite2D.new()
	sprite.texture = texture

	var base_scale = desired_size / max(texture.get_width(), texture.get_height())
	var scale_factor = base_scale * randf_range(0.8, 1.2)
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.modulate = modulate_color

	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = CircleShape2D.new()
	collision_shape.shape.radius = desired_size * scale_factor / base_scale / 2

	parent.add_child(sprite)
	parent.add_child(collision_shape)

	return sprite

func create_satellite(parent = self, is_sub_satellite = false):
	var satellite = Area2D.new()
	satellite.add_to_group("meteorite")

	var texture
	var size
	if is_sub_satellite:
		texture = satellite_without_moons_texture
		size = sub_satellite_size
	elif randf() > 0.5:
		texture = satellite_without_moons_texture
		size = satellite_size
	else:
		texture = satellite_with_moons_texture
		size = satellite_size

	create_celestial_body(satellite, texture, size)

	var orbit_radius
	if parent == self:
		if available_orbits.is_empty():
			return
		orbit_radius = available_orbits.pop_at(randi() % available_orbits.size())
	else:
		orbit_radius = randf_range(size * 2, size * 4)

	var angle = randf() * 2 * PI
	satellite.position = Vector2(cos(angle), sin(angle)) * orbit_radius

	var orbital_speed = randf_range(min_orbital_speed, max_orbital_speed)
	var clockwise = randf() > 0.5
	var initial_angle = angle

	parent.add_child(satellite)

	var sat_data = SatelliteData.new()
	sat_data.node = satellite
	sat_data.parent_node = parent
	sat_data.orbit_radius = orbit_radius
	sat_data.orbital_speed = orbital_speed
	sat_data.clockwise = clockwise
	sat_data.initial_angle = initial_angle
	sat_data.current_angle = initial_angle 

	satellites.append(sat_data)

	if not is_sub_satellite and texture == satellite_with_moons_texture:
		for i in range(max_sub_satellites):
			if randf() < satellite_chance:
				create_satellite(satellite, true)

func _process(delta):
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		var is_visible_s = distance_to_player <= visibility_threshold
		update_visibility_and_movement(is_visible_s, delta)

func update_visibility_and_movement(is_visible_s, delta):

	for child in get_children():
		if child is Sprite2D or child is CollisionShape2D:
			child.visible = is_visible_s
			if child is CollisionShape2D:
				child.set_deferred("disabled", not is_visible_s)

	for sat_data in satellites:
		var satellite = sat_data.node

		for child in satellite.get_children():
			if child is Sprite2D or child is CollisionShape2D:
				child.visible = is_visible_s
				if child is CollisionShape2D:
					child.set_deferred("disabled", not is_visible_s)
		if is_visible_s:

			var orbital_speed = sat_data.orbital_speed
			var clockwise = sat_data.clockwise
			sat_data.current_angle += orbital_speed * delta * (-1 if clockwise else 1)
			

			var orbit_center = sat_data.parent_node.global_position
			var orbit_radius = sat_data.orbit_radius
			var angle = sat_data.current_angle
			var new_pos = Vector2(cos(angle), sin(angle)) * orbit_radius
			satellite.global_position = orbit_center + new_pos
