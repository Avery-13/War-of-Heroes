extends CharacterBody3D

var speed: float = 5.0
var target_position: Vector3 = Vector3.ZERO
var is_selected: bool = false
var attack_range: float = 6.0  # Range within which the unit can attack
var actions: Array[String] = []

const STOPPING_DISTANCE: float = 0.5  # Distance to stop before the target position

@onready var selection_indicator = $SelectionIndicator  # Reference to the selection indicator
var target_factory: Node3D = null  # Reference to the target factory
var target_enemy_factory: Node3D = null  # Reference to the target enemy factory
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var animation_player : AnimationPlayer = $AnimationUnit

func _ready():
	# Worker units can move and convert factories
	if is_in_group("Ally_Worker"):
		actions = ["Move", "Convert"]

	# Combat units
	elif is_in_group("Ally_Units"):
		actions = ["Move", "Attack Nearest", "Guard", "Rest"]

	# HQs 
	elif is_in_group("Ally_HQ"):
		actions = ["Create Unit", "Build Structure"]  # Add more when implemented

	# Enemy units 
	elif is_in_group("Enemy_Units"):
		actions = ["Attack"]  # Enemies aren't controlled by player

func select() -> void:
	is_selected = true
	selection_indicator.visible = true  # Show the selection indicator

func deselect() -> void:
	is_selected = false
	selection_indicator.visible = false  # Hide the selection indicator

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

func return_selected():
	return is_selected

func convert_factory(factory: Node3D) -> void:
	if is_in_group("Ally_Worker") and is_selected:
		target_factory = factory
		move_to(factory.global_transform.origin)  # Move to factory first

func _physics_process(delta: float) -> void:
	if target_position != Vector3.ZERO:
		var distance_to_target = global_transform.origin.distance_to(target_position)

		if distance_to_target > STOPPING_DISTANCE:	
			var direction = (target_position - global_transform.origin).normalized()
			velocity = direction * speed
			update_animation_parameters("move") # play move animation
			var look_pos = global_position - direction 
			look_pos.y = global_position.y  # Keep the y-coordinate the same
			look_at(look_pos , Vector3.UP)  # Look at the target position
			# look_at(global_transform.origin - direction, Vector3.UP)
			move_and_slide()
		
		else:
			# Stop moving when close to the target
			velocity = Vector3.ZERO
			target_position = Vector3.ZERO
			update_animation_parameters("idle") # play idle animation
		# Check if reached target factory
		if target_factory and global_transform.origin.distance_to(target_position) < 3.0:
			if global_transform.origin.distance_to(target_factory.global_transform.origin) <= 3.0:
				_complete_conversion()
			target_position = Vector3.ZERO
		
		if is_instance_valid(target_enemy_factory):
			if global_transform.origin.distance_to(target_position) < 1.5:
				if global_transform.origin.distance_to(target_enemy_factory.global_transform.origin) <= attack_range:
					_convert_enemy_factory()
				target_position = Vector3.ZERO

			
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
