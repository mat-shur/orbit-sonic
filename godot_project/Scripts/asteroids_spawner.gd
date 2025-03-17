extends Node2D

@export var rocket_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var warning_duration: float = 1.5
@export var spawn_height: float = 2500.0
@export var screen_width: float = 1280

var player: Node2D
var ui: CanvasLayer

func _ready():
	player = $"../../Player/Player"
	ui = $"../../Player/Player/UI"

	start_spawning()

func start_spawning():
	while true:
		var spawn_x = randf_range(-500, +500)
		var spawn_position = Vector2(player.position.x + spawn_x, player.position.y - spawn_height)
		spawn_rocket(spawn_position)
		await get_tree().create_timer(2).timeout 

func show_warning(spawn_x):
	var warning = Label.new()
	warning.text = "!"
	warning.add_theme_color_override("font_color", Color(1, 0, 0)) 
	warning.add_theme_font_size_override("font_size", 40) 

	warning.position = Vector2(
		player.get_canvas_transform().origin.x + spawn_x,
		0 
	)
	
	ui.add_child(warning)
	
	var tween = create_tween()
	tween.tween_property(warning, "modulate:a", 0, warning_duration)
	tween.tween_callback(warning.queue_free)

func spawn_rocket(spawn_position: Vector2):
	var rocket = rocket_scene.instantiate()
	rocket.position = Vector2(spawn_position.x, player.position.y - spawn_height)
	add_child(rocket)
