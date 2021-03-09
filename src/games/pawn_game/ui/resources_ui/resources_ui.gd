extends VBoxContainer

onready var gold_label: Label = $gold

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_resource(resource: String, value: int):
	print("UI")
	match resource:
		"Gold":
			update_gold(value)

func update_gold(gold_amount: int):
	gold_label.text = "Gold: " + str(gold_amount)
