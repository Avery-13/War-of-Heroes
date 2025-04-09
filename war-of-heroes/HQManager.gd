# HQManager.gd
extends Node

var ally_hq_health_bar: Node3D
var enemy_hq_health_bar: Node3D

# HQ health values
var ally_hq_health := 1000
var ally_hq_max_health := 1000
var enemy_hq_health := 1000
var enemy_hq_max_health := 1000

# References to HQ nodes
var ally_hq: Node3D
var enemy_hq: Node3D

func _ready():
	
	# Find HQs in the scene
	ally_hq = get_node("/root/Node3D/StaticBody3D_HQ_Player")
	ally_hq_health_bar = ally_hq.get_child(0)
	enemy_hq = get_node("/root/Node3D/StaticBody3D_HQ_Enemy")
	enemy_hq_health_bar = enemy_hq.get_child(0)
	
	# Verify we found them
	if not ally_hq:
		push_error("Ally HQ not found!")
	if not enemy_hq:
		push_error("Enemy HQ not found!")

# Damage functions
func damage_ally_hq(amount: int):
	ally_hq_health = max(ally_hq_health - amount, 0)
	_check_hq_status("ally")
	if ally_hq_health_bar && ally_hq_health_bar.has_method("update_health"):
		ally_hq_health_bar.update_health(ally_hq_health, ally_hq_max_health)

func damage_enemy_hq(amount: int):
	enemy_hq_health = max(enemy_hq_health - amount, 0)
	_check_hq_status("enemy")
	if enemy_hq_health_bar && enemy_hq_health_bar.has_method("update_health"):
		print("Enemy HQ damaged! Current health: ", enemy_hq_health)
		enemy_hq_health_bar.update_health(enemy_hq_health, ally_hq_max_health)

# Status checking
func _check_hq_status(hq_type: String):
	match hq_type:
		"ally":
			if ally_hq_health <= 0:
				print("Ally HQ destroyed!")
				# Add game over logic here
				ally_hq.queue_free()
		"enemy":
			if enemy_hq_health <= 0:
				print("Enemy HQ destroyed!")
				# Add victory logic here
				enemy_hq.queue_free()

# # Visual updates (if you have health bars)
# func _update_hq_visuals():
# 	if ally_hq.has_method("update_health_display"):
# 		ally_hq.update_health_display(ally_hq_health, ally_hq_max_health)
# 	if enemy_hq.has_method("update_health_display"):
# 		enemy_hq.update_health_display(enemy_hq_health, enemy_hq_max_health)
