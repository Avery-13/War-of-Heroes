extends Node3D

@onready var progress_bar = $BarViewport/TextureProgressBar
@onready var sprite = $Sprite3D

func _ready():
	# Link Sprite3D to viewport texture
	sprite.texture = $BarViewport.get_texture()
	# Test (should show full bar)
	update_health(100, 100)

func update_health(current: int, max_health: int):
	# Update progress bar
	progress_bar.max_value = max_health
	progress_bar.value = current
	
	# Optional: Tint based on health (if using white textures)
	var health_percent = float(current) / max_health
	if health_percent < 0.3:
		progress_bar.modulate = Color.RED
	elif health_percent < 0.6:
		progress_bar.modulate = Color.YELLOW
	else:
		progress_bar.modulate = Color.GREEN
	
	# Force viewport update
	$BarViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
