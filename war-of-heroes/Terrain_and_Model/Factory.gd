extends Node3D

@onready var capture_indicator: MeshInstance3D = null
var is_captured: bool = false

func _ready():
    # Initialize capture state
    if is_in_group("Ally_Factory"):
        GameResources.active_factories += 1
        _set_captured(true)
    else:
        _set_captured(false)

func capture():
    if not is_inside_tree():
        return  # Ensure the node is in the scene tree
    if is_in_group("Empty_Factory"):
        remove_from_group("Empty_Factory")
        add_to_group("Ally_Factory")
        GameResources.active_factories += 1
        convert_to_ally()
        _set_captured(true)
        print("Factory captured by allies!")  # Debug message

func _set_captured(captured: bool):
    is_captured = captured
    
    if captured:
        _create_capture_indicator()
    else:
        _remove_capture_indicator()

func _create_capture_indicator():
    if capture_indicator != null:
        return  # Already exists
    
    # Create indicator mesh
    var circle_mesh = CylinderMesh.new()
    circle_mesh.top_radius = 2.5
    circle_mesh.bottom_radius = 2.5
    circle_mesh.height = 0.01
    
    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.YELLOW
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    
    # Create mesh instance
    capture_indicator = MeshInstance3D.new()
    capture_indicator.mesh = circle_mesh
    capture_indicator.material_override = material
    capture_indicator.position.y = -2.0  # Slightly above ground
    
    add_child(capture_indicator)

func _remove_capture_indicator():
    if capture_indicator:
        capture_indicator.queue_free()
        capture_indicator = null

func convert_to_ally():
    if is_in_group("Enemy_Factory"):
        remove_from_group("Enemy_Factory")
        add_to_group("Ally_Factory")
        GameResources.active_factories += 1
        _set_captured(true)
        print("Enemy factory converted to ally!")

func _exit_tree():
    if is_in_group("Ally_Factory"):
        GameResources.active_factories -= 1