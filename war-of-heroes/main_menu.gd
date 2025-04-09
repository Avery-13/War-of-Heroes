extends Control

var ui: CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ui = get_node("/root/Node3D/ResourceUI")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().paused = false
	ui.visible = true
	queue_free()
