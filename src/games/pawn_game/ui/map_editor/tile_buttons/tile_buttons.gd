extends HBoxContainer

var type_dict: Dictionary = {}

var selected: String = ""

signal type_selected(type)
signal type_deselected(type)

func create_buttons(res_dict: Dictionary):
	type_dict = res_dict.duplicate()
	for type in type_dict:
		create_button(type, type_dict[type])

func create_button(type: String, _res: Resource):
	var button: Button = Button.new()
	button.text = type
# warning-ignore:return_value_discarded
	button.connect("pressed", self, "_on_button_pressed", [type])
	add_child(button)

func select_type(type):
	print("type selected: ", type)
	selected = type
	emit_signal("type_selected", type)

func deselect_type(type):
	print("type deselected: ", type)
	selected = ""
	emit_signal("type_deselected", type)

func _on_button_pressed(type: String):
	if type == selected:
		deselect_type(selected)
		return
	if selected != "":
		deselect_type(selected)
	if type != selected:
		select_type(type)
