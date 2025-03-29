# GameManager.gd
extends Node

# Resources
var gold: int = 500
var iron: int = 300

# Unit/building lists 
var player_units: Array = []
var enemy_units: Array = []
var buildings: Array = []

func add_gold(amount: int) -> void:
	gold += amount
	update_hud()

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		update_hud()
		return true
	return false

func add_iron(amount: int) -> void:
	iron += amount
	update_hud()

func spend_iron(amount: int) -> bool:
	if iron >= amount:
		iron -= amount
		update_hud()
		return true
	return false

func update_hud():
	if get_tree().has_current_scene():
		var hud = get_tree().current_scene.get_node("HUD")
		if hud:
			hud.update_resource_labels()
