extends Panel

@onready var unit_grid = $UnitGrid  #GridContainer
@onready var unit_card_scene = preload("res://UnitCard.tscn")
@onready var game_resources = get_node("/root/GameResources")  # Reference to GameResources



# Alternative spawn position calculation for multiple points
var spawn_points = 20  # Number of spawn points around HQ
var current_spawn_index = 0
var spawn_radius = 6.0

var units = {
	"Worker": { 
		"cost_iron": 50, 
		"cost_gold": 100, 
		"icon": preload("res://Screenshot 2025-04-08 193653.png"),
		"scene": preload("res://Terrain_and_Model/Units/Worker.tscn")
	},
	"Infantry": { 
		"cost_iron": 100, 
		"cost_gold": 50, 
		"icon": preload("res://Screenshot 2025-04-08 193534.png"),
		"scene": preload("res://Terrain_and_Model/Units/Infantry.tscn") 
	},
	"Marksman": { 
		"cost_iron": 200, 
		"cost_gold": 100, 
		"icon": preload("res://Screenshot 2025-04-08 193737.png"),
		"scene": preload("res://Terrain_and_Model/Units/Marksman.tscn") 
	},
	"Tank": { 
		"cost_iron": 400, 
		"cost_gold": 200, 
		"icon": preload("res://Screenshot 2025-03-30 194949.png"),
		"scene": preload("res://Terrain_and_Model/Units/Tank.tscn")
	},
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	populate_unit_grid()
	GameResources.resources_updated.connect(_on_resources_updated)

func _on_resources_updated(iron: int, gold: int):
	# Update button states when resources change
	for card in unit_grid.get_children():
		var unit_data = units[card.get_node("NameLabel").text]
		card.get_node("BuyButton").disabled = not GameResources.can_afford(unit_data.cost_iron, unit_data.cost_gold)

func populate_unit_grid():
	# Clear existing cards
	for child in unit_grid.get_children():
		child.queue_free()
	
	# Create new cards
	for name in units.keys():
		var card = unit_card_scene.instantiate()
		var data = units[name]
		card.setup(name, data.cost_iron, data.icon, data.cost_gold)
		card.get_node("BuyButton").pressed.connect(_on_unit_purchased.bind(name))
		# Disable button if can't afford
		card.get_node("BuyButton").disabled = not GameResources.can_afford(data.cost_iron, data.cost_gold)
		unit_grid.add_child(card)

func _on_unit_purchased(unit_name: String):
	var unit_data = units[unit_name]
	if GameResources.spend_resources(unit_data.cost_iron, unit_data.cost_gold):
		spawn_unit(unit_name)
	else:
		print("Not enough resources to buy ", unit_name)

func spawn_unit(unit_name: String):
	var unit_data = units[unit_name]
	var unit_instance = unit_data.scene.instantiate()
	
	# Find HQ and get spawn position
	var hq = get_tree().get_nodes_in_group("Ally_HQ")
	if hq.size() > 0:
		var angle = (2 * PI / spawn_points) * current_spawn_index
		var spawn_position = hq[0].global_transform.origin
		spawn_position += Vector3(sin(angle), 0, cos(angle)) * spawn_radius
		
		current_spawn_index = (current_spawn_index + 1) % spawn_points
		
					
		# setting up node to group
		if unit_name == "Worker":
			unit_instance.add_to_group("Ally_Units")
			unit_instance.add_to_group("Ally_Worker")
		elif unit_name == "Infantry":
			unit_instance.add_to_group("Ally_Units")
			unit_instance.add_to_group("Ally_Infantry")
		elif unit_name == "Marksman":
			unit_instance.add_to_group("Ally_Units")
			unit_instance.add_to_group("Ally_Marksman")
		elif unit_name == "Tank":
			unit_instance.add_to_group("Ally_Units")
			unit_instance.add_to_group("Ally_Tank")
		
		# Add to scene
		get_tree().root.add_child(unit_instance)
		unit_instance.global_transform.origin = spawn_position
		print("Spawned ", unit_name, " near HQ at ", spawn_position)
		# Debug print number of Ally_Units
		var ally_units = get_tree().get_nodes_in_group("Ally_Units")
		print("Number of Ally Units: ", ally_units.size())
		
		# attach enemy ai script to the unit
		var script = preload("res://Terrain_and_Model/Unit.gd")
		unit_instance.set_script(script)
		unit_instance._ready()
		unit_instance.set_physics_process(true)
	else:
		print("No Ally HQ found - cannot spawn unit")
		unit_instance.queue_free()
		# Optionally refund resources if HQ is missing
		GameResources.iron += unit_data.cost_iron
		GameResources.gold += unit_data.cost_gold


func ai_spawn_unit(unit_name: String):
	var unit_data = units[unit_name]
	if GameResources.spend_ai_resources(unit_data.cost_iron, unit_data.cost_gold):
		var unit_instance = unit_data.scene.instantiate()
		
		# Find ai HQ and set spawn position
		var hq = get_tree().get_nodes_in_group("Enemy_HQ")
		if hq.size() > 0:
			#var angle = (2 * PI / spawn_points) * current_spawn_index
			# spawn on the left side of the HQ
			var angle_start = PI
			var angle_end = 2 * PI
			var angle = angle_start + (angle_end - angle_start) * float (current_spawn_index) / float(spawn_points)
			var spawn_position = hq[0].global_transform.origin
			spawn_position += Vector3(sin(angle), 0, cos(angle)) * spawn_radius 
			
			current_spawn_index = (current_spawn_index + 1) % spawn_points
			
			# setting up node to group
			if unit_name == "Worker":
				unit_instance.add_to_group("Enemy_Units")
				unit_instance.add_to_group("Enemy_Worker")
			elif unit_name == "Infantry":
				unit_instance.add_to_group("Enemy_Units")
				unit_instance.add_to_group("Enemy_Infantry")
			elif unit_name == "Marksman":
				unit_instance.add_to_group("Enemy_Units")
				unit_instance.add_to_group("Enemy_Marksman")
			elif unit_name == "Tank":
				unit_instance.add_to_group("Enemy_Units")
				unit_instance.add_to_group("Enemy_Tank")
			
			# Add to scene
			get_tree().root.add_child(unit_instance)
			unit_instance.global_transform.origin = spawn_position
			print("Spawned ", unit_name, " near AI HQ at ", spawn_position)
			
			# attach enemy ai script to the unit
			var ai_script = preload("res://Terrain_and_Model/EnemyAI.gd")
			unit_instance.set_script(ai_script)
			unit_instance._ready()
			unit_instance.set_physics_process(true)
			
			# Debug print number of Enemy_Units
			var enemy_units = get_tree().get_nodes_in_group("Enemy_Units")
			print("Number of AI Units: ", enemy_units.size())
		else:
			print("No Ally HQ found - cannot spawn unit")
			unit_instance.queue_free()
			# Optionally refund resources if HQ is missing
			GameResources.iron += unit_data.cost_iron
			GameResources.gold += unit_data.cost_gold
	else: 
			print("AI - Not enough resources to buy ", unit_name)	

func get_current_iron():
	return GameResources.enemy_iron

func get_current_gold():
	return GameResources.enemy_gold

func get_cost_iron(unit_name: String):
	return units[unit_name]["cost_iron"]

func get_cost_gold(unit_name: String):
	return units[unit_name]["cost_gold"]
