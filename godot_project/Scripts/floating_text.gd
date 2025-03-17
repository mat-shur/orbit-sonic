extends Label

var velocity = Vector2(0, -50) 
var duration = 2.0 

func _ready():
	var timer = Timer.new()
	timer.connect("timeout", Callable(self, "queue_free"))
	timer.set_wait_time(duration)
	timer.set_one_shot(true)
	add_child(timer)
	timer.start()

func _process(delta):
	position += velocity * delta
