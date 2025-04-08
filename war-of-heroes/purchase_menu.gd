extends Panel

@onready var unit_grid = $UnitGrid  #GridContainer
@onready var unit_card_scene = preload("res://UnitCard.tscn")
@onready var game_resources = get_node("/root/GameResources")  # Reference to GameResources



# Alternative spawn position calculation for multiple points
var spawn_points = 20  # Number of spawn points around HQ
var current_spawn_index = 0
var spawn_radius = 6.0

var units = {
	"Infantry": { 
		"cost_iron": 100, 
		"cost_gold": 5, 
		"icon": preload("res://icon.svg"),
		"scene": preload("res://Terrain_and_Model/Units/Infantry.tscn") 
	},
	"Worker": { 
		"cost_iron": 50, 
		"cost_gold": 5, 
		"icon": preload("res://icon.svg"),
		"scene": preload("res://Terrain_and_Model/Units/Worker.tscn")
	},
	"Tank": { 
		"cost_iron": 300, 
		"cost_gold": 5, 
		"icon": preload("res://icon.svg"),
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
		card.setup(name, data.cost_iron, data.icon)
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
		
		# Add to scene
		get_tree().root.add_child(unit_instance)
		unit_instance.global_transform.origin = spawn_position
		print("Spawned ", unit_name, " near HQ at ", spawn_position)
		# Debug print number of Ally_Units
		var ally_units = get_tree().get_nodes_in_group("Ally_Units")
		print("Number of Ally Units: ", ally_units.size())
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
		
		# Find ai HQ and get spawn position
		var hq = get_tree().get_nodes_in_group("Enemy_HQ")
		if hq.size() > 0:
			var angle = (2 * PI / spawn_points) * current_spawn_index
			var spawn_position = hq[0].global_transform.origin
			spawn_position += Vector3(sin(angle), 0, cos(angle)) * spawn_radius 
			
			current_spawn_index = (current_spawn_index + 1) % spawn_points
			
			# setting up node to group
			if unit_name == "Worker":
				unit_instance.add_to_group("Enemy_Units")
				unit_instance.add_to_group("Enemy_Worker")
			
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
