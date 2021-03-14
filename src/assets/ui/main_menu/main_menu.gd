extends Control

onready var color_picker: ColorPicker = $ColorPicker

func _ready():
	#hide dropper in ColorPicker
	color_picker.get_children()[1].get_children()[1].hide()
	#give color rect literally any fucking height
	color_picker.get_children()[1].get_children()[0].rect_min_size.y = 25

func _on_Button_pressed():
	if $name.text != "":
		Network.myName = $name.text
		Network.myColor = color_picker.color
		Network.client($ip.text)

func _on_hostButton_pressed():
	if $name.text != "":
		Network.myName = $name.text
		Network.myColor = color_picker.color
		Network.host()
