# HUD.gd
extends CanvasLayer

@onready var gold_label = $TopBar/GoldLabel
@onready var iron_label = $TopBar/IronLabel

func _ready():
	update_resource_labels()

func update_resource_labels():
	gold_label.text = "Gold: %d" % GameManager.gold
	iron_label.text = "Iron: %d" % GameManager.iron
