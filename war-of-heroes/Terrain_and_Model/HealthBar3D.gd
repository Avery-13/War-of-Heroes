extends Node3D

@onready var progress_bar = $SubViewport/TextureProgressBar

func update_health(value: int, max_value: int):
	progress_bar.max_value = max_value
	progress_bar.value = value
	# Optional: Change color based on health percentage
	var health_percent = float(value) / max_value
	if health_percent < 0.3:
		progress_bar.tint_progress = Color.RED
	elif health_percent < 0.6:
		progress_bar.tint_progress = Color.YELLOW
	else:
		progress_bar.tint_progress = Color.GREEN
