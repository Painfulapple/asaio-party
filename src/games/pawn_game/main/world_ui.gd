extends Node2D

onready var camera: Camera2D = get_parent().get_node("pawn_game_cam")
onready var interact_popup: Control = $CanvasLayer/interact_popup#$interact_popup

var is_mouse_down: bool = false
var mouse_down_pos: Vector2 = Vector2(0, 0)

signal interaction_selected(interaction, tile)
signal new_order(order)
signal box_selection_completed(start, end)

func _ready():
# warning-ignore:return_value_discarded
	get_parent().connect("tile_created", self, "tile_created")
# warning-ignore:return_value_discarded
	interact_popup.connect("interaction_selected", self, "interaction_selected")
# warning-ignore:return_value_discarded
	interact_popup.connect("new_order", self, "new_order")

func _draw():
	if not is_mouse_down:
		return
	var mousePos = mouse_down_pos
	var rect = Rect2(mousePos.x, mousePos.y, get_global_mouse_position().x - mousePos.x, get_global_mouse_position().y - mousePos.y)
	# draw filled transparent rectangle
	draw_rect(rect, Color(.5, 1, 1, .25))
	# draw solid outline
	draw_rect(rect, Color(.5, 1, 1), false)

func _unhandled_input(event):
	if not event is InputEventMouse:
		return
	if event is InputEventMouseButton:
		if not event.button_index == BUTTON_LEFT:
			return
		if event.pressed:
			is_mouse_down = true
			mouse_down_pos = get_global_mouse_position()#event.global_position
		else:
			is_mouse_down = false
			emit_signal("box_selection_completed", mouse_down_pos, get_global_mouse_position())
			return
	update()

func tile_interacted_with(tile: Node2D, input: InputEventMouseButton):
	print(tile, " interacted with")
	#print(tile.orders)
	# uncomment for crash, used for testing
	#print(get_node_or_null("sdgf").x)
	interact_popup.show_interactions(tile.orders, input.position, tile)

func tile_created(tile):
	#print("tile created, ", tile)
	tile.connect("interacted_with", self, "tile_interacted_with")

func interaction_selected(interaction, tile):
	emit_signal("interaction_selected", interaction, tile)

func new_order(order: PawnOrder):
	emit_signal("new_order", order)
