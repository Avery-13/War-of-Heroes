extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup(unit_name: String, cost_iron: int, icon: Texture2D, cost_gold: int = 5):
	$NameLabel.text = unit_name
	$CostLabel.text = "Iron: %d\nGold: %d" % [cost_iron, cost_gold]
	$Icon.texture = icon
	$BuyButton.pressed.connect(func():
		print("Buy pressed for: ", unit_name)
	)
