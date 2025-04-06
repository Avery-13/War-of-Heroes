extends Node3D

# Reference to the AnimationPlayer
@onready var animation_player : AnimationPlayer

func _ready():
	# Get the AnimationPlayer node
	animation_player = $AnimationPlayer
	# Default into idleanimation
	var animation: Animation = animation_player.get_animation("Running")
	animation.loop_mode = Animation.LOOP_LINEAR
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
	
