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

var active_factories: int = 0:
    set(value):
        active_factories = max(value, 0)
        _update_income_rate()

var base_iron_income: int = 5
var factory_iron_bonus: int = 10

func _ready():
    var timer = Timer.new()
    add_child(timer)
    timer.timeout.connect(_generate_resources)
    timer.start(1.0)

func _update_income_rate():
    print("Active factories: ", active_factories)  # Debug

func _generate_resources():
    var total_iron_income = base_iron_income + (active_factories * factory_iron_bonus)
    iron += total_iron_income
    gold += 5  # Gold stays at base rate
    print("Income: +", total_iron_income, " Iron")  # Debug

func can_afford(cost_iron: int, cost_gold: int) -> bool:
    return iron >= cost_iron and gold >= cost_gold

func spend_resources(cost_iron: int, cost_gold: int) -> bool:
    if can_afford(cost_iron, cost_gold):
        iron -= cost_iron
        gold -= cost_gold
        return true
    return false