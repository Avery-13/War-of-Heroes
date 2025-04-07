extends Node3D

@onready var capture_indicator: MeshInstance3D = null
var is_captured: bool = false
var factory_type: String = "Iron" # Default factory type

func _ready():

	#Detect factory type from name
	if "Gold" in name:
		factory_type = "Gold"
	elif "Iron" in name:
		factory_type = "Iron"

	# Initialize capture state
	if is_in_group("Ally_Factory"):
		GameResources.active_factories[factory_type] += 1
		_set_captured(true, "ally")
	else:
		_set_captured(false, "ally")
	
	if is_in_group("Enemy_Factory"):
		GameResources.active_enemy_factories[factory_type] += 1
		_set_captured(true, "enemy")
	else:
		_set_captured(false,"enemy")

func capture(unit: Node3D):
	if not is_inside_tree():
		return  # Ensure the node is in the scene tree
	# if its player capture
	if is_in_group("Empty_Factory") and unit.is_in_group("Ally_Units") :
		remove_from_group("Empty_Factory")
		add_to_group("Ally_Factory")
		GameResources.active_factories[factory_type] += 1
		print (GameResources.active_factories)  # Debug message
		convert_to_ally()
		_set_captured(true, "ally")
		print("The following factory has been captured: ", factory_type)  # Debug message
	#if its enemy capture
	elif is_in_group("Empty_Factory") and unit.is_in_group("Enemy_Units") :
		remove_from_group("Empty_Factory")
		add_to_group("Enemy_Factory")
		GameResources.active_enemy_factories[factory_type] += 1
		print (GameResources.active_enemy_factories)  # Debug message
		convert_to_enemy()
		_set_captured(true, "enemy")
		print("The following factory has been captured by the enemy: ", factory_type)  # Debug message

func _set_captured(captured: bool, unit: String):
	is_captured = captured
	
	if captured:
		_create_capture_indicator(unit)
	else:
		_remove_capture_indicator()

func _create_capture_indicator(unit: String):
	if capture_indicator != null:
		return  # Already exists
	
	
	# Create indicator mesh
	var circle_mesh = CylinderMesh.new()
	circle_mesh.top_radius = 2.5
	circle_mesh.bottom_radius = 2.5
	circle_mesh.height = 0.01
	
	# Create material
	var material = StandardMaterial3D.new()
	if (unit == "ally"):
		material.albedo_color = Color.YELLOW
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	elif (unit == "enemy"):
		material.albedo_color = Color.RED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
	# Create mesh instance
	capture_indicator = MeshInstance3D.new()
	capture_indicator.mesh = circle_mesh
	capture_indicator.material_override = material
	capture_indicator.position.y = -2.0  # Slightly above ground
	print("Capture indicator created!")  # Debug message
	
	add_child(capture_indicator)

func _remove_capture_indicator():
	if capture_indicator:
		capture_indicator.queue_free()
		capture_indicator = null

func convert_to_ally():
	if is_in_group("Enemy_Factory"):
		remove_from_group("Enemy_Factory")
		add_to_group("Ally_Factory")
		GameResources.active_factories[factory_type] += 1
		_set_captured(true, "ally")
		print("Enemy factory converted to ally!")

func convert_to_enemy():
	if is_in_group("Ally_Factory"):
		remove_from_group("Ally_Factory")
		add_to_group("Enemy_Factory")
		GameResources.active_factories[factory_type] += 1
		_set_captured(true, "enemy")
		print("Ally factory converted to enemy!")

func _exit_tree():
	if is_in_group("Ally_Factory"):
		GameResources.active_factories[factory_type] -= 1
