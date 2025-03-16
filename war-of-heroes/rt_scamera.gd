extends Node3D

@export var move_speed: float = 20.0  # Speed of movement
@export var zoom_speed: float = 2.0   # Speed of zooming
@export var min_zoom: float = 10.0    # Minimum zoom height
@export var max_zoom: float = 50.0    # Maximum zoom height
@export var edge_scroll_speed: float = 20.0  # Speed when moving via screen edges
@export var edge_scroll_margin: int = 20  # Pixels from screen edge to trigger movement

var camera: Camera3D
var selectedUnit: CharacterBody3D
var ally_units

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = $Camera3D  # Get the camera reference
	ally_units = get_tree().get_nodes_in_group("Ally_Units") # Gets all the ally units in the Node -> Scene Groups


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var move_direction = Vector3.ZERO
	var mouse_position = get_viewport().get_mouse_position()
	var screen_size = get_viewport().get_visible_rect().size


	# Keyboard Movement
	if Input.is_action_pressed("move_forward") or mouse_position.y < edge_scroll_margin:
		move_direction.z -= 1
	if Input.is_action_pressed("move_backward") or mouse_position.y > screen_size.y - edge_scroll_margin:
		move_direction.z += 1
	if Input.is_action_pressed("move_left") or mouse_position.x < edge_scroll_margin:
		move_direction.x -= 1
	if Input.is_action_pressed("move_right") or mouse_position.x > screen_size.x - edge_scroll_margin:
		move_direction.x += 1
		
	# Normalize diagonal movement
	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()

	# Apply movement
	position += move_direction * move_speed * delta
	
	# Camera Movement based on Tracking an ally Unit 
	if Input.is_action_pressed("ui_accept"): 
		for unit in ally_units:
			if (unit.return_selected() == true):
				selectedUnit = unit
				position = selectedUnit.position + Vector3(0, 0, camera.size)
	
func _input(event):
	if event is InputEventMouseMotion:
		return  # Ignore mouse motion events

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size += zoom_speed

		# Clamp zoom to avoid going too low or too high
		camera.size = clamp(camera.size, min_zoom, max_zoom)
