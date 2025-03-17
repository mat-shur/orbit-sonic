extends Node2D

@export var laser_scene: PackedScene  # Сцена лазерного бар'єра (LaserBarrier.tscn)
@export var spawn_interval: float = 1.0  # Інтервал спавну лазерів (в секундах)
@export var horizontal_margin: float = 0.0  # Маржа по краям, за бажанням

var player : Node2D = null

func _ready() -> void:
	# Спочатку створюємо один лазер одразу
	spawn_random_laser()
	# Далі запускаємо нескінченний цикл спавну


func spawn_random_laser() -> void:
	# Отримуємо розміри екрану
	var screen_rect = get_viewport_rect()
	# Генеруємо випадкову горизонтальну позицію (в межах екрану)
	var spawn_x = randf_range(-500, +500)
	# Створюємо екземпляр лазера
	var laser_instance = laser_scene.instantiate()
	# Встановлюємо позицію лазера: по горизонталі випадкова, по вертикалі – 0 (ColorRect займає всю висоту)
	laser_instance.global_position = Vector2(player.global_position.x + spawn_x, player.global_position.y - 3000)
	# Додаємо лазер до поточної сцени
	get_parent().add_child(laser_instance)


func _on_timer_timeout() -> void:
	if player.global_position.y < global_position.y + 250 and player.global_position.y > global_position.y - 7500:
		spawn_random_laser()
