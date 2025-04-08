extends Panel

@onready var action_list = $ActionList  # VBoxContainer node


# accepts a callback that runs when a button is pressed
func show_actions(actions: Array[String], action_callback: Callable):
	clear_actions()
	
	for action_name in actions:
		var btn = Button.new()
		btn.text = action_name
		

		btn.pressed.connect(func():
			print("Action pressed: ", action_name)
			action_callback.call(action_name)
		)
		
		action_list.add_child(btn)
		
func clear_actions():
	for child in action_list.get_children():
		child.queue_free()
