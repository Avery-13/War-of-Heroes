extends CharacterBody3D

# Health and Combat Stats
var health: int = 100
var max_health: int = 100
var speed: float = 5.0
var attack_damage: int = 10
var attack_range: float = 6.0
var attack_cooldown: float = 1.0
var time_since_last_attack: float = 0.0

# Navigation and Targeting
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var target_position: Vector3 = Vector3.ZERO
var current_target: Node3D
var target_factory: StaticBody3D = null
var target_enemy_factory: Node3D = null
var attack_target: Node3D = null

# AI Behavior Parameters
var detection_radius: float = 30.0
var hq_detection_radius: float = 50.0
var factory_detection_radius: float = 100.0
var retreat_distance: float = 40.0
var is_retreat: bool = false
var timer 
var enemy_near_

# Unit Type Values
var infantry_value: int = 1
var marksman_value: int = 2
var tank_value: int = 3
var hero_value: int = 4

# References
@onready var selection_indicator = $SelectionIndicator
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationUnit
var player_hq_building: Node3D
var ai_hq_building: Node3D

func _ready():
	# create timer instance
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout) 
	
	# Navigation setup
	navigation_agent.path_desired_distance = 1
	navigation_agent.target_desired_distance = 2
	navigation_agent.path_max_distance = 10
	
	# Get HQ references
	player_hq_building = get_node("/root/Node3D/StaticBody3D_HQ_Player")
	ai_hq_building = get_node("/root/Node3D/StaticBody3D_HQ_Enemy")
	
	# Initialize unit stats based on type
	if "Enemy_Worker" in get_groups():
		_setup_worker()
	elif "Enemy_Infantry" in get_groups():
		_setup_infantry()
	elif "Enemy_Marksman" in get_groups():
		_setup_marksman()
	elif "Enemy_Tank" in get_groups():
		_setup_tank()
	elif "Enemy_Hero" in get_groups():
		_setup_hero()
	
	actor_setup.call_deferred()

func actor_setup():
	await get_tree().physics_frame
	set_movement_target(player_hq_building.position)

# Unit type specific setups
func _setup_worker():
	health = 40
	max_health = 80
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

# Damage handling
func take_damage(amount: int):
	health -= amount
	health = max(health, 0)
	if health <= 0:
		die()

func die():
	print(name, " has died!")
	queue_free()

# Movement and combat
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func attack(enemy: Node3D) -> void:
	if enemy.is_in_group("Enemy_Factory"):
		target_enemy_factory = enemy
		set_movement_target(enemy.global_transform.origin)
	else:
		attack_target = enemy
		set_movement_target(enemy.global_transform.origin)

func destroy_enemy(enemy: Node3D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(attack_damage)
	else:
		enemy.queue_free()
	print("Enemy destroyed!")

func _physics_process(delta: float) -> void:
	time_since_last_attack += delta
	
	# AI decision making
	var worker = "Enemy_Worker" in get_groups()
	var infantry = "Enemy_Infantry" in get_groups()
	var marksman = "Enemy_Marksman" in get_groups()
	var tank = "Enemy_Tank" in get_groups()
	var hero = "Enemy_Hero" in get_groups()
	
	# All units get the retreat option
	if worker or infantry or marksman or tank or hero:
		var player_strength = get_nearby_player_strength()
		var ai_strength = get_nearby_ai_strength()
		# if the player strength is higher then the AI stregnth in the area, retreat
		if player_strength > ai_strength and is_retreat == false: 
			is_retreat = true  
			timer.start()
			timer.wait_time = 5
			retreat()
		# if units is not retreating and the player stregnth is not higher, attack
		else:
			if is_retreat == false:
				if infantry or marksman or tank or hero:
					# attack nearby player units if they exist
					var target = prioritize_target()
					if target != null:
						attack(target)
					# or if there are no nearby targets, but there are ally units near ai factories and the unit itself is nearby, defend the factory
					elif (target == null and player_units_nearby_factory!= null):
						var help_factory = player_units_nearby_factory()
						if (help_factory != null):
							timer.start()
							timer.wait_time = 5
							set_movement_target(help_factory.position)
					# otherwise attack the player HQ
					else:
						set_movement_target(player_hq_building.position)
	
	# workers will find the cloest empty factory to capture
	if worker:
		locate_closest_empty_factory()
	
	# Navigation and movement
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position = global_position
	var next_path_position = navigation_agent.get_next_path_position()

	if next_path_position != null:
		var direction = current_agent_position.direction_to(next_path_position)
		
		if direction.length() > 0.01:
			velocity = direction * speed
			# if the direction is not aligned with the up vector (to avoid "look_at" error)
			if direction.cross(Vector3.UP).length() > 0.01:
				look_at(current_agent_position - direction, Vector3.UP)
			# if the direction is aligned with the up vector, use the right vector to avoid the issue
			else:
				look_at(current_agent_position - direction, Vector3.RIGHT)
			
		if navigation_agent.distance_to_target() > 0.5:
			move_and_slide()
			update_animation_parameters("move")
	
	# Combat handling
	if is_instance_valid(attack_target):
		var dist_to_enemy = global_position.distance_to(attack_target.global_position)
		
		if dist_to_enemy <= attack_range:
			velocity = Vector3.ZERO
			if time_since_last_attack >= attack_cooldown:
				update_animation_parameters("fire")
				destroy_enemy(attack_target)
				time_since_last_attack = 0.0
			else:
				update_animation_parameters("idle")
		else:
			update_animation_parameters("move")

# AI behavior functions
func retreat():
	var retreat_position = global_position - (global_position - ai_hq_building.position).normalized() * retreat_distance
	set_movement_target(retreat_position)

func locate_closest_empty_factory():
	var closest_factory = null
	var min_distance = 999
	
	for factory in get_tree().get_nodes_in_group("Empty_Factory"):
		var distance = global_position.distance_to(factory.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_factory = factory
	
	if closest_factory:
		target_factory = closest_factory
		set_movement_target(target_factory.position)
		if global_position.distance_to(target_factory.position) < 3.0:
			_complete_conversion()
	else:
		set_movement_target(ai_hq_building.position)

func _complete_conversion():
	if is_instance_valid(target_factory) and target_factory.has_method("capture"):
		target_factory.capture(self)
		target_factory.convert_to_enemy()
	queue_free()

# Strength calculation functions
func get_nearby_player_strength():
	var strength = 0
	for unit in get_tree().get_nodes_in_group("Ally_Infantry"):
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
			strength += infantry_value
	for unit in get_tree().get_nodes_in_group("Ally_Marksman"):
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
			strength += marksman_value
	for unit in get_tree().get_nodes_in_group("Ally_Tank"):
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
			strength += tank_value
	for unit in get_tree().get_nodes_in_group("Ally_Hero"):
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
			strength += hero_value
	return strength

func get_nearby_ai_strength():
	var strength = 0
	for unit in get_tree().get_nodes_in_group("Enemy_Infantry"):
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
			strength += infantry_value
	for unit in get_tree().get_nodes_in_group("Enemy_Marksman"):
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
			strength += marksman_value
	for unit in get_tree().get_nodes_in_group("Enemy_Tank"):
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
			strength += tank_value
	for unit in get_tree().get_nodes_in_group("Enemy_Hero"):
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
			strength += hero_value
	return strength

# Target prioritization
func prioritize_target():
	var best_target = null
	var highest_priority = -999

	for unit in get_nearby_player_units():
		var priority = 0
		var distance = position.distance_to(unit.position)
		
		if "Enemy_Infantry" in get_groups():
			if "Ally_Worker" in unit.get_groups():
				priority = 4
			elif "Ally_Infantry" in unit.get_groups():
				priority = 5
			elif "Ally_Marksman" in unit.get_groups():
				priority = 3
			elif "Ally_Hero" in unit.get_groups():
				priority = 2
			elif "Ally_Tank" in unit.get_groups():
				priority = 1
		elif "Enemy_Marksman" in get_groups():
			if "Ally_Worker" in unit.get_groups():
				priority = 1
			elif "Ally_Infantry" in unit.get_groups():
				priority = 3
			elif "Ally_Marksman" in unit.get_groups():
				priority = 4
			elif "Ally_Hero" in unit.get_groups():
				priority = 5
			elif "Ally_Tank" in unit.get_groups():
				priority = 2
		elif "Enemy_Tank" in get_groups():
			if "Ally_Worker" in unit.get_groups():
				priority = 1
			elif "Ally_Infantry" in unit.get_groups():
				priority = 2
			elif "Ally_Marksman" in unit.get_groups():
				priority = 3
			elif "Ally_Hero" in unit.get_groups():
				priority = 5
			elif "Ally_Tank" in unit.get_groups():
				priority = 4
		elif "Enemy_Hero" in get_groups():
			if "Ally_Worker" in unit.get_groups():
				priority = 1
			elif "Ally_Infantry" in unit.get_groups():
				priority = 2
			elif "Ally_Marksman" in unit.get_groups():
				priority = 3
			elif "Ally_Hero" in unit.get_groups():
				priority = 4
			elif "Ally_Tank" in unit.get_groups():
				priority = 5
		
		priority -= distance / 10
		
		if priority > highest_priority:
			highest_priority = priority
			best_target = unit
	
	return best_target

func get_nearby_player_units():
	var units = []
	for group in ["Ally_Infantry", "Ally_Marksman", "Ally_Tank", "Ally_Hero"]:
		for unit in get_tree().get_nodes_in_group(group):
			if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
				units.append(unit)
	return units

func get_nearby_ai_units():
	var units = []
	for group in ["Enemy_Infantry", "Enemy_Marksman", "Enemy_Tank", "Enemy_Hero"]:
		for unit in get_tree().get_nodes_in_group(group):
			if is_instance_valid(unit) and global_position.distance_to(unit.global_position) <= detection_radius:
				units.append(unit)
	return units

func player_units_nearby_factory():				
	# determine if the unit is close enough to help any nearby ai factory
	var factory_list = []
	for factory in get_tree().get_nodes_in_group("Enemy_Factory"):
		if global_position.distance_to(factory.global_position) <= factory_detection_radius:
			factory_list.append(factory)
	
	var found_enemy = false
	var help_factory
	if (!factory_list.is_empty()):
		# determine if there is an enemy near the factory and store that factory
		for group in ["Ally_Infantry", "Ally_Marksman", "Ally_Tank", "Ally_Hero"]:
			for unit in get_tree().get_nodes_in_group(group):
				for factory in factory_list:
					if unit.global_position.distance_to(factory.global_position) <= factory_detection_radius:
						found_enemy = true
						help_factory = factory
						break
				if found_enemy == true:
					break
			if found_enemy == true:
				break
	
	# if enemy is found return that factory
	if (found_enemy == true):
		return help_factory
	# otherwise, return nothing
	else:
		return null

# timer for retreating
func _on_timer_timeout():
	is_retreat = false

# Animation control
func update_animation_parameters(action: String):
	if action == "move":
		animation_player.get_animation("Idle").loop_mode = Animation.LOOP_NONE
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_firing"] = false
		animation_player.get_animation("Running").loop_mode = Animation.LOOP_LINEAR
		animation_tree["parameters/conditions/is_moving"] = true
	elif action == "fire":
		animation_player.get_animation("Running").loop_mode = Animation.LOOP_NONE
		animation_tree["parameters/conditions/is_moving"] = false
		animation_tree["parameters/conditions/is_idle"] = false
		animation_tree["parameters/conditions/is_firing"] = true
	elif action == "idle":
		animation_player.get_animation("Running").loop_mode = Animation.LOOP_NONE
		animation_tree["parameters/conditions/is_moving"] = false
		animation_tree["parameters/conditions/is_firing"] = false
		animation_tree["parameters/conditions/is_idle"] = true
