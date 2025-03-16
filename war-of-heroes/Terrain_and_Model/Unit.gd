extends CharacterBody3D

var speed: float = 5.0
var target_position: Vector3 = Vector3.ZERO
var is_selected: bool = false

@onready var selection_indicator = $SelectionIndicator  # Reference to the selection indicator

func select() -> void:
    is_selected = true
    selection_indicator.visible = true  # Show the selection indicator

func deselect() -> void:
    is_selected = false
    selection_indicator.visible = false  # Hide the selection indicator

func move_to(new_target_position: Vector3) -> void:
    target_position = new_target_position

func _physics_process(delta: float) -> void:
    if target_position != Vector3.ZERO:
        var direction = (target_position - global_transform.origin).normalized()
        velocity = direction * speed
        move_and_slide()

        # Stop moving if close to the target
        if global_transform.origin.distance_to(target_position) < 0.5:
            target_position = Vector3.ZERO