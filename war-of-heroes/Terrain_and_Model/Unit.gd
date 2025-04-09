extends CharacterBody3D

# Base Stats for All Units
var health: int = 100
var max_health: int = 100
var speed: float = 5.0
var attack_damage: int = 10
var attack_range: float = 6.0  # Range within which the unit can attack
var attack_cooldown: float = 1.0  # Time between attacks
var time_since_last_attack: float = 0.0  # Timer for attack cooldown

# Health Bar
@onready var health_bar =   get_child(0) # Reference to the health bar node
@onready var health_bar_3d = $HealthBar3D  # Reference to the 3D health bar node

# Resource Collection
var resource_check_timer: float = 0.0
const RESOURCE_CHECK_INTERVAL: float = 0.5  # Time interval to check for resources
const PICKUP_RADIUS: float = 5.0  # Radius to check for resources

var target_position: Vector3 = Vector3.ZERO
var is_selected: bool = false
var guard_range: float = 10.0
var actions: Array[String] = []

const STOPPING_DISTANCE: float = 0.5  # Distance to stop before the target position

@onready var selection_indicator = $SelectionIndicator  # Reference to the selection indicator
var target_factory: Node3D = null  # Reference to the target factory
var target_enemy_factory: Node3D = null  # Reference to the target enemy factory
var attack_target: Node3D = null  # Currently targeted enemy to attack
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var animation_player : AnimationPlayer = $AnimationUnit

var is_guarding: bool = false
var attack_timer: float = 0.0

func _ready():
	# Initialize stats based on unit type
	if is_in_group("Ally_Worker") or is_in_group("Enemy_Worker"):
		_setup_worker()
	elif is_in_group("Ally_Infantry") or is_in_group("Enemy_Infantry"):
		_setup_infantry()
	elif is_in_group("Ally_Marksman") or is_in_group("Enemy_Marksman"):
		_setup_marksman()
	elif is_in_group("Ally_Tank") or is_in_group("Enemy_Tank"):
		_setup_tank()
	elif is_in_group("Ally_Hero") or is_in_group("Enemy_Hero"):
		_setup_hero()

	# Initialize health bar
	if health_bar && health_bar.has_method("update_health"):
		health_bar.update_health(health, max_health)
	
	# Initialize actions based on unit type
	if is_in_group("Ally_Worker"):
		actions = ["Convert"]
	elif is_in_group("Ally_Marksman"):
		actions = ["Attack Nearest", "Guard", "Rest"]
	elif is_in_group("Ally_Infantry"):
		actions = ["Attack Nearest", "Guard", "Rest"]
	elif is_in_group("Ally_Tank"):
		actions = ["Attack Nearest", "Guard", "Rest"]
	elif is_in_group("Ally_Turrent"):
		actions = ["Attack Nearest", "Guard", "Rest"]
	elif is_in_group("Ally_Hero"):
		actions = ["Attack Nearest", "Guard", "Rest", "Ability"]

	# HQs 
	elif is_in_group("Ally_HQ"):
		actions = ["Create Unit", "Build Structure"]  # Add more when implemented

	# Enemy units 
	elif is_in_group("Enemy_Units"):
		actions = ["Attack"]  # Enemies aren't controlled by player

func _setup_worker():
	health = 300
	max_health = 300
	speed = 4.0

func _setup_infantry():
	health = 75
	max_health = 75
	speed = 5.0
	attack_damage = 30
	attack_range = 2.0
	attack_cooldown = 1.5

func _setup_marksman():
	health = 50
	max_health = 50
	speed = 4.5
	attack_damage = 25
	attack_range = 10.0
	attack_cooldown = 2.0

func _setup_tank():
	health = 150
	max_health = 150
	speed = 3.0
	attack_damage = 50
	attack_range = 15.0
	attack_cooldown = 3.0

func _setup_hero():
	health = 100
	max_health = 100
	speed = 6.0
	attack_damage = 20
	attack_range = 3.0
	attack_cooldown = 1.0

func select() -> void:
	is_selected = true
	selection_indicator.visible = true  # Show the selection indicator

func deselect() -> void:
	is_selected = false
	selection_indicator.visible = false  # Hide the selection indicator

func move_to(new_target_position: Vector3) -> void:
	target_position = new_target_position

func take_damage(amount: int):
	health -= amount
	health = max(health, 0)
	print("health: ", health)
	if health_bar and health_bar.has_method("update_health"):
		print("healthbarrrrrrrrrrrrrrrr")
		health_bar.update_health(health, max_health)
	if health <= 0:
		die()

func die():
	print(name, " has died!")
	queue_free()

func attack(enemy: Node3D) -> void:
	# Workers can't attack
	if is_in_group("Ally_Worker"):
		print("Workers cannot attack!")
		return
	
	if enemy.is_in_group("Enemy_Factory"):
		# Special case for enemy factories
		target_enemy_factory = enemy
		move_to(enemy.global_transform.origin)
	elif enemy.is_in_group("Enemy_HQ"):
		# Attack enemy HQ
		attack_target = enemy
		move_to(enemy.global_transform.origin)
	else:
		# Normal attack behavior
		attack_target = enemy
		move_to(enemy.global_transform.origin)

func destroy_enemy(enemy: Node3D) -> void:
	enemy.queue_free()  # Destroy the enemy
	print("Enemy destroyed!")

func return_selected():
	return is_selected

func convert_factory(factory: Node3D) -> void:
	if is_in_group("Ally_Worker") and is_selected:
		target_factory = factory
		move_to(factory.global_transform.origin)  # Move to factory first

func _physics_process(delta: float) -> void:
	time_since_last_attack += delta
	# Resource pickup logic
	resource_check_timer += delta
	if resource_check_timer >= RESOURCE_CHECK_INTERVAL:
		resource_check_timer = 0.0
		_check_nearby_resources()
	# Movement logic
	if target_position != Vector3.ZERO:
		var distance_to_target = global_transform.origin.distance_to(target_position)

		if distance_to_target > STOPPING_DISTANCE:    
			var direction = (target_position - global_transform.origin).normalized()
			velocity = direction * speed
			update_animation_parameters("move")
			var look_pos = global_position - direction 
			look_pos.y = global_position.y  # Keep the y-coordinate the same
			look_at(look_pos, Vector3.UP)
			move_and_slide()
		
		else:
			# Stop moving when close to the target
			velocity = Vector3.ZERO
			target_position = Vector3.ZERO
			update_animation_parameters("idle")
			
			# Check if reached target factory for conversion
			if target_factory and global_transform.origin.distance_to(target_factory.global_transform.origin) <= 3.0:
				_complete_conversion()
				target_position = Vector3.ZERO
			
			# Check if reached enemy factory for attack
			if is_instance_valid(target_enemy_factory):
				if global_transform.origin.distance_to(target_enemy_factory.global_transform.origin) <= attack_range:
					_convert_enemy_factory()
				target_position = Vector3.ZERO
	
	# Combat logic
	if is_instance_valid(attack_target):
		var dist_to_enemy = global_transform.origin.distance_to(attack_target.global_transform.origin)
		
		if dist_to_enemy <= attack_range:
			# Stop moving when in attack range
			velocity = Vector3.ZERO
			target_position = Vector3.ZERO
			
			# Attack if cooldown is ready
			if time_since_last_attack >= attack_cooldown:
				print("Attacking enemy:", attack_target.name)
				update_animation_parameters("fire")
				print("Target has method take_damage:", attack_target.has_method("take_damage"))
				if attack_target.has_method("take_damage"):
					attack_target.take_damage(attack_damage)
					print("Dealt ", attack_damage, " damage to ", attack_target.name, " remaining health: ", attack_target.health)
				elif attack_target.is_in_group("Enemy_HQ"):
					HQManager.damage_enemy_hq(attack_damage)
				elif attack_target.is_in_group("Ally_HQ"):
					HQManager.damage_ally_hq(attack_damage)
				time_since_last_attack = 0.0
			else:
				update_animation_parameters("idle")
		else:
			# Move toward enemy if out of range
			target_position = attack_target.global_transform.origin
			update_animation_parameters("move")
				
	#guard process
	if is_guarding:
		attack_timer -= delta

		# Search for enemies in range
		for enemy in get_tree().get_nodes_in_group("Enemy_Units"):
			if not is_instance_valid(enemy):
				continue
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= guard_range:
				if attack_timer <= 0.0:
					print("Guarding unit attacking:", enemy.name)
					attack(enemy)
					attack_timer = attack_cooldown
				break  # Only attack one at a time

func _check_nearby_resources():
	# Only check nodes in the "Resources" group
	for resource in get_tree().get_nodes_in_group("Resources"):
		# Skip if not a StaticBody3D or too far away
		if not resource is StaticBody3D:
			continue
		if global_position.distance_to(resource.global_position) > PICKUP_RADIUS:
			continue
			
		var resource_name = resource.name.to_lower()
		var resources = GameResources
		
		if not resources:
			printerr("GameResources node not found!")
			continue
			
		# Handle different resource types
		if "health" in resource_name:
			_handle_health_resource(resource)
		elif "construction" in resource_name:
			_handle_construction_resource(resource, resources)
		elif "money" in resource_name:
			_handle_money_resource(resource, resources)

func _handle_health_resource(resource: StaticBody3D):
	var unit_group = "Ally_Units" if is_in_group("Ally_Units") else "Enemy_Units"
	_heal_nearby_units(unit_group)
	_destroy_resource(resource)

func _handle_construction_resource(resource: StaticBody3D, resources: Node):
	if is_in_group("Ally_Units"):
		resources.iron += 10
	else:
		resources.enemy_iron += 10
	_destroy_resource(resource)

func _handle_money_resource(resource: StaticBody3D, resources: Node):
	if is_in_group("Ally_Units"):
		resources.gold += 10
	else:
		resources.enemy_gold += 10
	_destroy_resource(resource)

func _heal_nearby_units(unit_group: String):
	var heal_amount = 10
	var heal_radius = 5.0
	
	for unit in get_tree().get_nodes_in_group(unit_group):
		if unit != self and global_position.distance_to(unit.global_position) <= heal_radius:
			unit.health = min(unit.health + heal_amount, unit.max_health)
			if unit.has_method("update_health_display"):
				unit.update_health_display()

func _destroy_resource(resource: StaticBody3D):
	# Optional: Play effect before destroying
	if resource.has_node("PickupEffect"):
		var effect = resource.get_node("PickupEffect")
		effect.emitting = true
		effect.reparent(get_tree().current_scene)
	
	resource.queue_free()

func rest():
	print("Resting...")
	target_position = Vector3.ZERO
	update_animation_parameters("idle")
	# Regenerate health over time
	health += 1
	health = min(health, max_health)  # Ensure health doesn't exceed max
	health_bar.update_health(health, max_health)

func attack_nearest_enemy():
	var nearest_enemy: Node3D = null
	var min_distance = INF

	for enemy in get_tree().get_nodes_in_group("Enemy_Units"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			nearest_enemy = enemy

	if nearest_enemy:
		print("Attacking nearest enemy:", nearest_enemy.name)
		attack(nearest_enemy)
	else:
		print("No enemy units found.")


func perform_action(action_name: String) -> void:
	match action_name:
		"Move":
			print("Move action selected — waiting for click on map")
			

		"Attack Nearest":
			attack_nearest_enemy()

		"Guard":
			print("Unit is now guarding.")
			is_guarding = true
			velocity = Vector3.ZERO
			target_position = Vector3.ZERO
			update_animation_parameters("idle")

		"Rest":
			rest()

		"Convert":
			print("Click on a factory to convert it.")
			

		"Attack":
			print("Click on a target to attack.")
			

		"Create Unit":
			print("TODO: Create unit")  

		"Build Structure":
			print("TODO: Build structure UI")

		_:
			print("Unknown action:", action_name)
			
func _complete_conversion():
	if is_instance_valid(target_factory) and target_factory.has_method("capture"):
		target_factory.capture(self)
	queue_free()  # Remove the worker after conversion
	target_factory = null  # Clear the reference

func _convert_enemy_factory():
	if target_enemy_factory and target_enemy_factory.has_method("convert_to_ally"):
		target_enemy_factory.convert_to_ally()
	target_enemy_factory = null


func update_animation_parameters(action: String):
	# move 
	if ("Ally_Tank" not in get_groups()):
		if (action == "move"):
			animation_player.get_animation("Idle").loop_mode = Animation.LOOP_NONE
			animation_tree["parameters/conditions/is_idle"] = false
			animation_player.get_animation("Idle").loop_mode = Animation.LOOP_NONE
			animation_tree["parameters/conditions/is_firing"] = false
			animation_player.get_animation("Running").loop_mode = Animation.LOOP_LINEAR		
			animation_tree["parameters/conditions/is_moving"] = true
		# fire
		elif (action == "fire"):
			animation_player.get_animation("Running").loop_mode = Animation.LOOP_NONE
			animation_tree["parameters/conditions/is_moving"] = false
			animation_player.get_animation("Idle").loop_mode = Animation.LOOP_NONE
			animation_tree["parameters/conditions/is_idle"] = false
			animation_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
			animation_tree["parameters/conditions/is_firing"] = true

		#idle
		elif (action == "idle"):
			animation_player.get_animation("Running").loop_mode = Animation.LOOP_NONE
			animation_tree["parameters/conditions/is_moving"] = false
			animation_player.get_animation("Idle").loop_mode = Animation.LOOP_NONE
			animation_tree["parameters/conditions/is_firing"] = false
			animation_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
			animation_tree["parameters/conditions/is_idle"] = true
