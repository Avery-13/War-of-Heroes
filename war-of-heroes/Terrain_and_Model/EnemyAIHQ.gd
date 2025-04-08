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
	timer.start()
	timer.wait_time = 10
	timer.timeout.connect(_on_timer_timeout) 
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# strategy to decide which units to create evey minute
func _on_timer_timeout():	
	# randomize a weight for each unit to make the decision more dynamic by randomly priorizing units
	var worker_weight = randf_range(0.5, 1.5)
	var infantry_weight = randf_range(0.5, 1.5)
	var marksman_weight = randf_range(0.3, 1.3)
	var tank_weight = randf_range(0.1, 1.1)
	
	# normalize the weight to 1.0
	var total_weight = infantry_weight + marksman_weight + tank_weight + worker_weight
	worker_weight /= total_weight
	infantry_weight /= total_weight 
	marksman_weight /= total_weight
	tank_weight /= total_weight
	
	# deteremine which troops to buy depending on the ai's current resources
	# formula: unit weight * (ai total iron / unit iron cost) * (ai total gold / unit gold cost) 
	var worker_iron = worker_weight * (purchase_menu.get_current_iron() / purchase_menu.get_cost_iron("Worker"))
	var worker_gold = worker_weight * (purchase_menu.get_current_gold() / purchase_menu.get_cost_gold("Worker"))
	var infantry_iron = infantry_weight * (purchase_menu.get_current_iron() / purchase_menu.get_cost_iron("Infantry"))
	var infantry_gold = infantry_weight * (purchase_menu.get_current_gold() / purchase_menu.get_cost_gold("Infantry"))
	var marksman_iron = marksman_weight * (purchase_menu.get_current_iron() / purchase_menu.get_cost_iron("Marksman"))
	var marksman_gold = marksman_weight * (purchase_menu.get_current_gold() / purchase_menu.get_cost_gold("Marksman"))
	var tank_iron = tank_weight * (purchase_menu.get_current_iron() / purchase_menu.get_cost_iron("Tank"))
	var tank_gold = tank_weight * (purchase_menu.get_current_gold() / purchase_menu.get_cost_gold("Tank"))
	
	# the amount of units needed for a type is limited by the whichever resource is less available
	var worker_amount = min(worker_iron, worker_gold)
	var infantry_amount = min(infantry_iron, infantry_gold)
	var marksman_amount = min(marksman_iron, marksman_gold)
	var tank_amount = min(tank_iron, tank_gold)	
	
	# purchase the needed units 
	for i in range(tank_amount):
		purchase_menu.ai_spawn_unit("Tank")
	for i in range(marksman_amount):
		purchase_menu.ai_spawn_unit("Marksman")
	for i in range(infantry_amount):
		purchase_menu.ai_spawn_unit("Infantry")
	for i in range(worker_amount):
		# purchase workers only if there are more empty factories then the amount of workers on the fields 
		var total_empty_factories = get_tree().get_nodes_in_group("Empty_Factory").size()
		var total_workers_existing = get_tree().get_nodes_in_group("Enemy_Worker").size()
		if (total_empty_factories > total_workers_existing):
			purchase_menu.ai_spawn_unit("Worker")
