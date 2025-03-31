extends Panel

@onready var unit_grid = $UnitGrid  #GridContainer
@onready var unit_card_scene = preload("res://UnitCard.tscn")

var units = {
	"Infantry": { "cost": 100, "icon": preload("res://icon.svg") },
	"Worker": { "cost": 50, "icon": preload("res://icon.svg") },
	"Tank": { "cost": 300, "icon": preload("res://icon.svg") },
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	populate_unit_grid()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func populate_unit_grid():
	var children =unit_grid.get_children()
	for child in children:
		child.queue_free()

	
	for name in units.keys():
		var card = unit_card_scene.instantiate()
		var data = units[name]
		card.setup(name, data.cost, data.icon)
		unit_grid.add_child(card)
