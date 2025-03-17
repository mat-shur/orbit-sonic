extends Node

@export var player_node_path: NodePath = "../Player/Player"
@export var check_interval: float = 3.0  
@export var max_distance: float = 12000.0  
@export var batch_size: int = 5 

var player: Node2D
var to_delete_nodes: Array
var current_index: int = 0

func _ready():
	player = get_node(player_node_path)
	if not player:
		push_error("Player node not found!")
		return
	
	var timer = Timer.new()
	timer.connect("timeout", Callable(self, "_on_check_timer_timeout"))
	timer.set_wait_time(check_interval)
	timer.set_one_shot(false)
	add_child(timer)
	timer.start()

func _on_check_timer_timeout():
	to_delete_nodes = get_tree().get_nodes_in_group("to_delete") + get_tree().get_nodes_in_group("comet")
	current_index = 0
	set_process(true)

func _process(_delta):
	var end_index = min(current_index + batch_size, to_delete_nodes.size())
	
	for i in range(current_index, end_index):
		var node = to_delete_nodes[i]
		if is_instance_valid(node):
			check_and_delete_node(node)
	
	current_index = end_index
	
	if current_index >= to_delete_nodes.size():
		set_process(false)

func check_and_delete_node(node):
	var node_position = node.global_position
	if node_position:
		var distance = player.global_position.distance_to(node_position)
		if distance > max_distance:
			node.queue_free()

func get_node_position(node):
	if node is Node2D:
		return node.global_position
	elif node.get_parent() is Node2D:
		return node.get_parent().global_position
	return null


func force_clean():
	_on_check_timer_timeout()
