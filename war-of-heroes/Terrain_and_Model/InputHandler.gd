extends Node3D

var selected_unit: Node3D = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			handle_right_click()

func handle_left_click(mouse_position: Vector2) -> void:
	var ray_origin = $RTScamera/Camera3D.project_ray_origin(mouse_position)
	var ray_direction = $RTScamera/Camera3D.project_ray_normal(mouse_position)
	var ray_length = 1000  # Adjust this value based on your scene size

	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	var ray_result = space_state.intersect_ray(ray_query)

	if ray_result:
		if ray_result.collider.is_in_group("Ally_Units"):
			select_unit(ray_result.collider)
		elif ray_result.collider.is_in_group("Enemy_Units") and selected_unit:
			attack_enemy(ray_result.collider)
		elif selected_unit:
			move_unit(ray_result.position)

func handle_right_click() -> void:
	if selected_unit:
		deselect_unit()

func select_unit(unit: Node3D) -> void:
	if selected_unit:
		selected_unit.deselect()  # Deselect the previously selected unit
	selected_unit = unit
	selected_unit.select()  # Highlight or indicate selection

func deselect_unit() -> void:
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null

func move_unit(target_position: Vector3) -> void:
	if selected_unit:
		selected_unit.move_to(target_position)

func attack_enemy(enemy: Node3D) -> void:
	if selected_unit:
		selected_unit.attack(enemy)
