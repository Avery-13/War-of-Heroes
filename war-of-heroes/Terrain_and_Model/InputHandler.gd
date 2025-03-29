extends Node3D

var camera: Camera3D
var selected_unit: Node3D = null:
	set(value):
		# Clear previous selection
		if is_instance_valid(selected_unit):
			selected_unit.deselect()
		# Set new value
		selected_unit = value
		# Select new unit if valid
		if is_instance_valid(selected_unit):
			selected_unit.select()
var selected_building: Node3D = null

func _ready():
	# Method 1: Try absolute path from root
	camera = get_node("/root/Node3D/RTScamera/Camera3D") 
	
	# Method 2: If that fails, search whole tree
	if !camera:
		camera = find_child("Camera3D", true, false)
	
	# Method 3: Final fallback to viewport camera
	if !camera:
		camera = get_viewport().get_camera_3d()
	
	if !camera:
		printerr("FATAL ERROR: No camera found! Check these:")
		print("All nodes:", get_tree().get_root().get_children())
		print("Camera nodes:", get_tree().get_nodes_in_group("cameras"))
	else:
		print("SUCCESS: Found camera:", camera.name)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_right_click()

func handle_left_click(mouse_position: Vector2) -> void:
	if !is_instance_valid(camera):
		printerr("Camera lost! Re-acquiring...")
		camera = get_viewport().get_camera_3d()
		if !camera:
			return
	# Get raycast information
	print("Mouse position: ", mouse_position)
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_direction = camera.project_ray_normal(mouse_position)
	var ray_length = 1000
	
	# Perform raycast
	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	var ray_result = space_state.intersect_ray(ray_query)
	
	if not ray_result:
		print("Raycast hit nothing")
		return  # Nothing was clicked
	
	var clicked_object = ray_result.collider
	var position_clicked = ray_result.position
	
	# Debug information
	print("Clicked object: ", clicked_object.name)
	print("Object groups: ", clicked_object.get_groups())
	if clicked_object.get_parent():
		print("Parent groups: ", clicked_object.get_parent().get_groups())
	
	# 1. Check for worker -> empty factory interaction
	if selected_unit and is_instance_valid(selected_unit) and selected_unit.is_in_group("Ally_Worker"):
		var factory = _find_factory_in_parents(clicked_object)
		if is_instance_valid(factory) and factory.is_in_group("Empty_Factory"):
			selected_unit.convert_factory(factory)
			# Deselect the unit after command
			selected_unit.deselect()
			selected_unit = null
			return
	
	# 2. Check for combat unit -> enemy factory interaction
	if selected_unit and not selected_unit.is_in_group("Ally_Worker"):
		var factory = _find_factory_in_parents(clicked_object)
		if factory and factory.is_in_group("Enemy_Factory"):
			print("Combat unit commanded to attack enemy factory")
			selected_unit.attack(factory)
			return
	
	# 3. Check for unit selection
	if clicked_object.is_in_group("Ally_Units"):
		print("Selecting unit")
		select_unit(clicked_object)
		return
	
	# 4. Check for factory selection
	var factory = _find_factory_in_parents(clicked_object)
	if factory and (factory.is_in_group("Empty_Factory") or 
				   factory.is_in_group("Ally_Factory") or 
				   factory.is_in_group("Enemy_Factory")):
		print("Selecting factory")
		select_building(factory)
		return
	
	# 5. Check for enemy unit attack
	if clicked_object.is_in_group("Enemy_Units") and selected_unit:
		print("Attacking enemy unit")
		attack_enemy(clicked_object)
		return
	
	# 6. Default movement command
	if selected_unit:
		print("Moving to position")
		selected_unit.move_to(position_clicked)

# Helper function to find factory nodes in parent hierarchy
func _find_factory_in_parents(node: Node) -> Node3D:
	var current = node
	while current:
		if current.is_in_group("Empty_Factory") or current.is_in_group("Ally_Factory"):
			return current
		current = current.get_parent()
	return null

func select_unit(unit: Node3D) -> void:
	# Deselect current selections
	deselect_current()
	
	selected_unit = unit
	selected_unit.select()

func select_building(building: Node3D) -> void:
	# Deselect current selections
	deselect_current()
	
	selected_building = building
	selected_building.select()

func deselect_current() -> void:
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null
	if selected_building:
		selected_building.deselect()
		selected_building = null

func handle_right_click() -> void:
	deselect_current()

func attack_enemy(enemy: Node3D) -> void:
	if selected_unit:
		selected_unit.attack(enemy)

func handle_unit_command(position: Vector3, clicked_object: Node3D):
	if selected_unit.is_in_group("Ally_Worker"):
		var factory = _find_factory_in_parents(clicked_object)
		if factory and factory.is_in_group("Empty_Factory"):
			selected_unit.convert_factory(factory)
			return
	
	# Default movement
	selected_unit.move_to(position)
