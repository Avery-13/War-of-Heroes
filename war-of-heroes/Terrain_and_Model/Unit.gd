extends CharacterBody3D

var speed: float = 5.0
var target_position: Vector3 = Vector3.ZERO
var is_selected: bool = false
var attack_range: float = 5.0  # Range within which the unit can attack

@onready var selection_indicator = $SelectionIndicator  # Reference to the selection indicator

func select() -> void:
	is_selected = true
	selection_indicator.visible = true  # Show the selection indicator

func deselect() -> void:
	is_selected = false
	selection_indicator.visible = false  # Hide the selection indicator

func move_to(new_target_position: Vector3) -> void:
	target_position = new_target_position

func attack(enemy: Node3D) -> void:
	target_position = enemy.global_transform.origin  # Move toward the enemy
	# Check if the enemy is within attack range
	if global_transform.origin.distance_to(enemy.global_transform.origin) <= attack_range:
		destroy_enemy(enemy)

func destroy_enemy(enemy: Node3D) -> void:
	enemy.queue_free()  # Destroy the enemy
	print("Enemy destroyed!")

func return_selected():
	return is_selected

func _physics_process(delta: float) -> void:
	if target_position != Vector3.ZERO:
		var direction = (target_position - global_transform.origin).normalized()
		velocity = direction * speed

		# Rotate the unit to face the movement direction
		look_at(global_transform.origin - direction, Vector3.UP)

		move_and_slide()

		# Stop moving if close to the target
		if global_transform.origin.distance_to(target_position) < 0.5:
			target_position = Vector3.ZERO
