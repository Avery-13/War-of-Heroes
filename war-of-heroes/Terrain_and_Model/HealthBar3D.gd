extends Node3D

@onready var progress_bar = get_child(1)
@onready var sprite = $Sprite3D

func _ready():
	# Link Sprite3D to viewport texture
	sprite.texture = $BarViewport.get_texture()
	# Test (should show full bar)
	update_health(100, 100)

func update_health(current: int, max_health: int):
	# Update progress bar
	var bar = progress_bar.get_child(0)
	bar.max_value = max_health
	bar.value = current
	
	# Optional: Tint based on health (if using white textures)
	var health_percent = float(current) / max_health
	if health_percent < 0.3:
		bar.modulate = Color.RED
	elif health_percent < 0.6:
		bar.modulate = Color.YELLOW
	else:
		bar.modulate = Color.GREEN
	
	# Force viewport update
	$BarViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
