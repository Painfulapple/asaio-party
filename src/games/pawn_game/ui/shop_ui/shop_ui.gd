extends Control

export var pawn_price: int = 1
onready var main = get_parent().get_parent()

onready var buy_pawn_button: Button = $HBoxContainer/Button

signal pawn_purchased

func _ready():
	buy_pawn_button.connect("pressed", self, "buy_pawn_button_pressed")

func buy_pawn_button_pressed():
	if(main.get_resource_amount("Gold") > 0):
		emit_signal("pawn_purchased")
		main.update_resource("Gold",-1)
