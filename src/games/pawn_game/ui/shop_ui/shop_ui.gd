extends Control

export var pawn_price: int = 1
onready var main = get_parent().get_parent()

onready var buy_pawn_button: Button = $HBoxContainer/Button

signal pawn_purchased

func _ready():
# warning-ignore:return_value_discarded
	buy_pawn_button.connect("pressed", self, "buy_pawn_button_pressed")

func buy_pawn_button_pressed():
	if(main.get_resource_amount("Gold") >= pawn_price):
		emit_signal("pawn_purchased")
		main.update_resource("Gold", -pawn_price)

func get_resource_amount(resource: String) -> int:
	return main.get_resource_amount(resource)
