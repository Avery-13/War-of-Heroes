extends CharacterBody3D

var speed: float = 5.0
var target_position: Vector3 = Vector3.ZERO
#var is_selected: bool = false
var attack_range: float = 6.0  # Range within which the unit can attack

@onready var selection_indicator = $SelectionIndicator  # Reference to the selection indicator
var target_factory: Node3D = null  # Reference to the target factory
var target_enemy_factory: Node3D = null  # Reference to the target enemy factory
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var animation_player : AnimationPlayer = $AnimationUnit


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var movement_target_position: Vector3 = Vector3(-3.0,0.0,2.0)


func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	
	# Make sure to not await during _ready.
	actor_setup.call_deferred()


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	var hq_building_pos = get_node("/root/Node3D/StaticBody3D_HQ_Player")

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(hq_building_pos.position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func _physics_process(delta: float) -> void:
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
		
	if navigation_agent.distance_to_target() > 1.0:
		#look_at(global_transform.origin - direction, Vector3.UP)
		move_and_slide()
		update_animation_parameters("move") # play move animation

		#move_and_slide()
		#
		## Check if reached target factory
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

#func return_selected():
#	return is_selected

func convert_factory(factory: Node3D) -> void:
	if is_in_group("Ally_Worker"):
		target_factory = factory
		move_to(factory.global_transform.origin)  # Move to factory first

func _complete_conversion():
	if is_instance_valid(target_factory) and target_factory.has_method("capture"):
		target_factory.capture()
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
