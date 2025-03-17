extends Area2D

@export var pre_warning_duration: float = 1.0  # Час, протягом якого лазер має початковий тусклий вигляд
@export var active_duration: float = 3.0       # Час, протягом якого лазер яскраво горить
@export var pre_warning_color: Color = Color(1, 1, 1, 0.0)  # Тьмяний червоний (RGBA: 1,0,0,0.5)
@export var active_color: Color = Color(1, 1, 1, 1.0)         # Яскравий червоний
@export var laser_width: float = 20.0           # Ширина лазера

var color_rect: ColorRect
var collision_shape: CollisionShape2D
var active = false

func _ready() -> void:
	# Припускаємо, що ColorRect та CollisionShape2D знаходяться як дочірні ноди
	color_rect = $ColorRect
	collision_shape = $CollisionShape2D
	
	# Отримуємо розміри екрану і встановлюємо висоту лазера відповідно до нього
	var screen_size = get_viewport_rect().size * 5
	color_rect.size = Vector2(laser_width, screen_size.y)
	
	# Встановлюємо початковий тусклий колір
	color_rect.color = pre_warning_color
	color_rect.visible = true
	
	# Налаштовуємо CollisionShape2D: створюємо RectangleShape2D з extents, що відповідають половині розміру ColorRect
	var rect_shape = RectangleShape2D.new()
	rect_shape.extents = color_rect.size / 2
	collision_shape.shape = rect_shape
	# За замовчуванням вимикаємо колізії
	collision_shape.disabled = true
	
	# Запускаємо цикл станів лазера
	run_cycle()

func run_cycle() -> void:
	# Перший крок: поступове затемнення
	await create_tween().tween_property(color_rect, "color", Color(1, 1, 1, 0.4), 0.8).finished
	await create_tween().tween_property(color_rect, "color", Color(1, 1, 1, 1), 0.5).finished
	
	# Після завершення попереднього tween-а активуємо лазер
	active = true
	collision_shape.disabled = false
	
	# Другий крок: лазер активний, потім зникає
	await create_tween().tween_property(color_rect, "color", Color(1, 1, 1, 1), 1.0).finished
	await create_tween().tween_property(color_rect, "color", Color(1, 1, 1, 0.0), 0.5).finished
	
	queue_free()

func set_active_true() -> void:
	active = true
	collision_shape.disabled = false
