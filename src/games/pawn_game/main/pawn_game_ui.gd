extends CanvasLayer

export var main_path: NodePath
export var map_editor_path: NodePath
export var shop_ui_path: NodePath
export var resources_ui_path: NodePath
export var interact_popup_path: NodePath
export var map_editor_only: bool = false

onready var main: Node2D = get_node(main_path)
onready var map_editor: Control = get_node(map_editor_path)
onready var shop_ui: Control = get_node(shop_ui_path)
onready var resources_ui: VBoxContainer = get_node(resources_ui_path)
onready var interact_popup: PopupMenu = get_node(interact_popup_path)

signal pawn_purchased
signal interaction_selected(interaction, tile)
signal new_order(order)
signal resource_updated(resource, value)

# Called when the node enters the scene tree for the first time.
func _ready():
# warning-ignore:return_value_discarded
	main.connect("tile_created", self, "tile_created")
# warning-ignore:return_value_discarded
	main.connect("my_castle_created", self, "my_castle_created")
# warning-ignore:return_value_discarded
	shop_ui.connect("pawn_purchased", self, "pawn_purchased")
# warning-ignore:return_value_discarded
	#interact_popup.connect("interaction_selected", self, "interaction_selected")
# warning-ignore:return_value_discarded
	interact_popup.connect("new_order", self, "new_order")
# warning-ignore:return_value_discarded
	main.connect("resource_updated", self, "resource_updated")
	if map_editor_only:
		for child in get_children():
			if not child == map_editor:
				child.hide()

func tile_interacted_with(tile: Node2D, input: InputEventMouseButton):
	print(tile, " interacted with")
	#print(tile.orders)
	# uncomment for crash, used for testing
	#print(get_node_or_null("sdgf").x)
	interact_popup.show_interactions(tile.orders, input.position, tile)

func tile_created(tile):
	#print("tile created, ", tile)
	tile.connect("interacted_with", self, "tile_interacted_with")

func pawn_purchased():
	emit_signal("pawn_purchased")

func interaction_selected(interaction, tile):
	emit_signal("interaction_selected", interaction, tile)

func new_order(order: PawnOrder):
	emit_signal("new_order", order)

func resource_updated(resource, value):
	emit_signal("resource_updated", resource, value)

func my_castle_created():
	if main.release_mode:
		map_editor.close_editor()
		map_editor.hide()
	shop_ui.show()
