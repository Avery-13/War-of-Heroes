extends StaticBody3D

# reference to the purchase menu script
var purchase_menu: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# load purchase menu script
	purchase_menu = get_node("/root/Node3D/ActionsUI/PurchaseMenu")
	
	# create timer instance
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2
	timer.start()
	timer.timeout.connect(_on_timer_timeout)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# triggered when timer times out
func _on_timer_timeout():
	print("purchased unit")
	purchase_menu.ai_spawn_unit("Worker")
