extends CanvasLayer

@onready var iron_label: Label = $Control/Panel/VBoxContainer/IronDisplay/IronAmount
@onready var gold_label: Label = $Control/Panel/VBoxContainer/GoldDisplay/GoldAmount

func _ready():
	# Connect to resource updates
	GameResources.resources_updated.connect(_update_display)
	_update_display(GameResources.iron, GameResources.gold)

func _update_display(iron: int, gold: int):
	iron_label.text = str(iron)
	gold_label.text = str(gold)
