extends CanvasLayer

@export var tween_duration: float = 0.7
@export var colors: Array = [
	Color(0.8, 0, 0),   # Red
	Color(0, 0.8, 0),   # Green
	Color(0, 0, 0.8),   # Blue
	Color(0.8, 0.8, 0),   # Yellow
	Color(0.8, 0, 0.8),   # Magenta
	Color(0, 0.8, 0.8)    # Cyan
]

var current_color_index: int = 0
var color_index: int = 0

var text: String = "! Nothing"

func _ready():
	$Control/Label.text = text
	
	#var tween = create_tween()
	#tween.tween_property($Control/ColorRect, "color", colors[color_index], tween_duration)
	#tween.tween_callback(color_rect_change)


func color_rect_change():
	color_index += 1
	
	if color_index >= 5:
		color_index = 0
	
	var tween = create_tween()
	tween.tween_property($Control/ColorRect, "color", colors[color_index], tween_duration)
	tween.tween_callback(color_rect_change)


func _on_timer_timeout() -> void:
	queue_free()
