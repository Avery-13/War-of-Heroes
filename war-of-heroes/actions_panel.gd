extends Panel

@onready var action_list = $ActionList  # Or whatever you named the VBoxContainer

func clear_actions():
	for child in action_list.get_children():
		child.queue_free()

func show_actions(actions: Array[String]):
	clear_actions()
	
	for action_name in actions:
		var btn = Button.new()
		btn.text = action_name
		
				# Connect the button's "pressed" signal to an inline function
		btn.pressed.connect(func():
			print("Action pressed: ", action_name)
		)
		
		action_list.add_child(btn)
