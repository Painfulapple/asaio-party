extends VBoxContainer

onready var pawn_game_ui: CanvasLayer = get_parent().get_parent()
onready var gold_label: Label = $gold

func _ready():
# warning-ignore:return_value_discarded
	pawn_game_ui.connect("resource_updated", self, "update_resource")

func update_resource(resource: String, value: int):
	print("UI")
	match resource:
		"Gold":
			update_gold(value)

func update_gold(gold_amount: int):
	gold_label.text = "Gold: " + str(gold_amount)
