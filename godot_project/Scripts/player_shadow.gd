extends Sprite2D

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.5)

func _on_timer_timeout() -> void:
	
	queue_free()
