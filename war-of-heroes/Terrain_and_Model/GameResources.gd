extends Node

signal resources_updated(iron, gold)

var iron: int = 100:
	set(value):
		iron = max(value, 0)
		resources_updated.emit(iron, gold)

var gold: int = 100:
	set(value):
		gold = max(value, 0)
		resources_updated.emit(iron, gold)

var active_factories: Dictionary = {
	"Iron": 0,
	"Gold": 0
}

var base_iron_income: int = 5
var factory_iron_bonus: int = 10
var base_gold_income: int = 5
var factory_gold_bonus: int = 10

func _ready():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_generate_resources)
	timer.start(1.0)

func _update_income_rate():
	print("Active factories - Iron: ", active_factories["Iron"], " Gold: ", active_factories["Gold"])  # Debug

func _generate_resources():
	# Calculate iron income
	var total_iron_income = base_iron_income + (active_factories["Iron"] * factory_iron_bonus)
	iron += total_iron_income
	
	# Calculate gold income
	var total_gold_income = base_gold_income + (active_factories["Gold"] * factory_gold_bonus)
	gold += total_gold_income
	
	print("Income: +", total_iron_income, " Iron, +", total_gold_income, " Gold")  # Debug

func can_afford(cost_iron: int, cost_gold: int) -> bool:
	return iron >= cost_iron and gold >= cost_gold

func spend_resources(cost_iron: int, cost_gold: int) -> bool:
	if can_afford(cost_iron, cost_gold):
		iron -= cost_iron
		gold -= cost_gold
		return true
	return false
