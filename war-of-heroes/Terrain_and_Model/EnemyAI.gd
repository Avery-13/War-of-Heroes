extends CharacterBody3D

# Note for this file. Because the Scene Groups is written from the Players POV.
# Ally_Units = Player units
# Enemy_Units = AI units


var speed: float = 5.0
var target_position: Vector3 = Vector3.ZERO
#var is_selected: bool = false
var attack_range: float = 6.0  # Range within which the unit can attack

@onready var selection_indicator = $SelectionIndicator  # Reference to the selection indicator
var target_factory: StaticBody3D = null  # Reference to the target factory
var target_enemy_factory: Node3D = null  # Reference to the target enemy factory
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var animation_player : AnimationPlayer = $AnimationUnit


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var current_target: Node3D
var player_hq_building: Node3D 
var ai_hq_building: Node3D 
	
var detection_radius: float = 50.0  # ai radius to detect other units
var hq_detection_radius: float = 50.0  # ai HQ radius to sense in range player's units  
var retreat_distance: float = 20.0  # distance to retreat if outnumbered by player units
var reinforcement_threshold: int = 3  # minimum number of reinforcements needed
var infantry_value: int = 1 # strength value of an infantry unit
var marksman_value: int = 2 # strength value of a marksman unit
var tank_value: int = 3 # strength value of a tank unit
var hero_value: int = 4 # strength value of a hero unit

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	# set Player's HQ buliding position
	player_hq_building = get_node("/root/Node3D/StaticBody3D_HQ_Player")
	# set AI's HQ buliding position
	ai_hq_building = get_node("/root/Node3D/StaticBody3D_HQ_Enemy")
	# Make sure to not await during _ready.
	actor_setup.call_deferred()


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	#current_target =  get_node("/root/Node3D/StaticBody3D_HQ_Player").name
	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(player_hq_building.position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
	#print(movement_target)

func _physics_process(delta: float) -> void:
	# all units will retreat if the player units strength in the area is higher then theirs 
	if ("Enemy_Worker" in get_groups() or "Enemy_Infantry" in get_groups() or "Enemy_Marksman" in get_groups() or "Enemy_Tank" in get_groups() or "Enemy_Hero" in get_groups()):
		# if there are player units nearby the current area
		var player_strength = get_nearby_player_units()
		if player_strength > 0:
			# if the player units is stronger then the ai units
			var ai_strength = get_nearby_ai_units()
			if player_strength > ai_strength:
				# if the units are approaching the hq are are close, defend the area by attacking them (workers will always retreat)
				if are_players_units_approaching_hq() and "Enemy_Worker" not in get_groups():
					defend()
				# otherwise, retreat and wait for reinforcements
				else:
					retreat()
	
	# infantry, marksman, tanks, and heroes will attack if the units in the area in stronger then the
	#if ("Enemy_Infantry" in get_groups() or "Enemy_Marksman" in get_groups() or "Enemy_Tank" in get_groups() or "Enemy_Hero" in get_groups()):
		

	# if its a worker
	if "Enemy_Worker" in get_groups():
		# locate for an existing empty factory (will capture if found, or wait at base if not)
		locate_closest_empty_factory()
		
		
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	# Calculate velocity toward the next path position
	var direction = current_agent_position.direction_to(next_path_position)
	#velocity = direction * movement_speed
	velocity = direction * speed
	if direction.length() > 0.01:  # Avoid rotating when already facing the target
		look_at(current_agent_position - direction, Vector3.UP)
		
	if navigation_agent.distance_to_target() > 0.5:
		#look_at(global_transform.origin - direction, Vector3.UP)
		move_and_slide()
		update_animation_parameters("move") # play move animation
		
		# Check if reached target factory
		#if target_factory and global_transform.origin.distance_to(target_position) < 3.0:
			#if global_transform.origin.distance_to(target_factory.global_transform.origin) <= 3.0:
				#_complete_conversion()
			#target_position = Vector3.ZERO
		#
		#if is_instance_valid(target_enemy_factory):
			#if global_transform.origin.distance_to(target_position) < 1.5:
				#if global_transform.origin.distance_to(target_enemy_factory.global_transform.origin) <= attack_range:
					#_convert_enemy_factory()
				#target_position = Vector3.ZERO
				

				

# get all nearby ally units total strength
func get_nearby_player_units():
	var player_strength = 0
	
	# check all ally units strength within the area
	for unit in get_tree().get_nodes_in_group("Ally_Infantry"):
		if global_position.distance_to(unit.global_position) <= detection_radius:
			player_strength += infantry_value
			
	for unit in get_tree().get_nodes_in_group("Ally_Marksman"):
		if global_position.distance_to(unit.global_position) <= detection_radius:
			player_strength += marksman_value
			
	for unit in get_tree().get_nodes_in_group("Ally_Tank"):
		if global_position.distance_to(unit.global_position) <= detection_radius:
			player_strength += tank_value
	
	for unit in get_tree().get_nodes_in_group("Ally_Hero"):
		if global_position.distance_to(unit.global_position) <= detection_radius:
			player_strength += hero_value
			
	return player_strength
	
# get all nearby enemy units 
func get_nearby_ai_units():
	var ai_strength = 0
	
	# check all enemy units strength within the area.
	for unit in get_tree().get_nodes_in_group("Enemy_Infantry"):
		if global_position.distance_to(unit.global_position) <= detection_radius:
			ai_strength += infantry_value
			
	for unit in get_tree().get_nodes_in_group("Enemy_Marksman"):
		if global_position.distance_to(unit.global_position) <= detection_radius:
			ai_strength += marksman_value
			
	for unit in get_tree().get_nodes_in_group("Enemy_Tank"):
		if global_position.distance_to(unit.global_position) <= detection_radius:
			ai_strength += tank_value
	
	for unit in get_tree().get_nodes_in_group("Enemy_Hero"):
		if global_position.distance_to(unit.global_position) <= detection_radius:
			ai_strength += hero_value
			
	return ai_strength
	
# determine if any of the player's units are heading towards the AI’s HQ base
func are_players_units_approaching_hq():
	var player_units = []
	for unit in get_tree().get_nodes_in_group("Ally_Units"):
		player_units.append(unit)
		
	# iterate over all the player units
	for player_unit in player_units:
		var direction_to_hq = player_unit.global_position.direction_to(ai_hq_building.position)
		var distance_to_hq = player_unit.global_position.distance_to(ai_hq_building.position)

		# check if the player's unit is heading toward the AI's HQ and they are within a specific range from the HQ 
		if distance_to_hq < hq_detection_radius and direction_to_hq.dot(ai_hq_building.position - player_unit.global_position) > 0.8:
			return true  # at least one of the player's units is heading toward the ai HQ

	return false  # none of the player's units are heading toward the ai HQ

# unit will retreat from the area
func retreat():
		print("Enemy is too strong. Retreating!")
		# move back a certain amount of distance towards the AI HQ
		var retreat_position = global_position - (global_position - ai_hq_building.position).normalized() * retreat_distance
		set_movement_target(retreat_position)
		return
		
# unit will defend the area
func defend():
	# units will attack the units to give HQ more time to create units to defend the HQ
	print("Player units are heading towards HQ. Preparing defense!")
	# add code to attack units
	return

# find the closet empty factory to capture
func locate_closest_empty_factory():
	var factory_distance = 999
	var closest_factory = null
	for unit in get_tree().get_nodes_in_group("Empty_Factory"):
		# if the distance of the empty factory is closer then the previous empty factories, store that node
		if global_position.distance_to(unit.global_position) < factory_distance:
			factory_distance = global_position.distance_to(unit.global_position)
			closest_factory = unit
	# capture the closest factory
	if (closest_factory != null):
		#print("Found empty factory")
		target_factory = closest_factory
		set_movement_target(target_factory.position)
		if global_transform.origin.distance_to(target_factory.position) < 3.0:
			print("converting to enemy factory")
			_complete_conversion()
	# otherwise, wait back at base
	else:
		print("no empty factory, waiting at base")
		set_movement_target(ai_hq_building.position)
	

   




#func select() -> void:
#	is_selected = true
#	selection_indicator.visible = true  # Show the selection indicator

#func deselect() -> void:
#	is_selected = false
#	selection_indicator.visible = false  # Hide the selection indicator

func move_to(new_target_position: Vector3) -> void:
	target_position = new_target_position

func attack(enemy: Node3D) -> void:
	# Workers can't attack
	if is_in_group("Ally_Worker"):
		print("Workers cannot attack!")
		return
	
	if enemy.is_in_group("Enemy_Factory"):
		# Special case for enemy factories
		target_enemy_factory = enemy
		move_to(enemy.global_transform.origin)
	else:
		# Normal attack behavior
		target_position = enemy.global_transform.origin
		if global_transform.origin.distance_to(enemy.global_transform.origin) <= attack_range:
			update_animation_parameters("fire") # play fire animation
			destroy_enemy(enemy)

func destroy_enemy(enemy: Node3D) -> void:
	enemy.queue_free()  # Destroy the enemy
	print("Enemy destroyed!")

func _complete_conversion():
	if is_instance_valid(target_factory) and target_factory.has_method("capture"):
		print("captured")
		target_factory.capture(self)
		target_factory.convert_to_enemy()
	queue_free()  # Remove the worker after conversion
	target_factory = null  # Clear the reference

func _convert_enemy_factory():
	if target_enemy_factory and target_enemy_factory.has_method("convert_to_ally"):
		target_enemy_factory.convert_to_ally()
	target_enemy_factory = null

func update_animation_parameters(action: String):
	# move 
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
