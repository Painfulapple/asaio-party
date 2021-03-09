extends Node2D

onready var controller: Node2D = get_parent()
onready var main: Node2D = controller.main
var map: Node2D

var basic_pawn_scene = load("res://games/pawn_game/pawns/pawn_basic/pawn_basic.tscn")

var player_id: int
var physics_layer: int

# player's castle tile
var castle: Node2D
var castle_pos: Vector2

var pawns: Array = []
enum PAWN_TYPES {BASIC, MEDIC, GIANT}
# list of pawns of certain type keyed by type int (based on PAWN_TYPES enum)
var pawns_by_type: Dictionary = {}

var pawns_created: int = 0

# node: coord
var pawn_reserved_coords: Dictionary = {}

signal pawn_selected(pawn)
signal pawn_deselected(pawn)
signal pawn_died(pawn)
signal my_castle_created

func _ready():
	if map == null:
		return
# warning-ignore:return_value_discarded
	map.connect("castle_created", self, "castle_created")
# warning-ignore:return_value_discarded
	main.connect("pawn_purchased", self, "pawn_purchased")
	set_network_master(player_id)
#	if is_network_master():
#		for _i in 50:
#			create_pawn(Vector2(rand_range(50, 974), rand_range(50, 550)))

func castle_created(tile: Node2D):
	if tile.player_id != player_id:
		return
	if castle != null:
		map.tile_destroyed(castle)
		for pawn in get_all_pawns():
			pawn.queue_free()
	castle = tile
	castle_pos = tile.global_position
	spawn_starting_pawns()
	if player_id == Network.get_my_id():
		emit_signal("my_castle_created")
#	print("new castle: ", castle_pos)

func pawn_purchased():
	if castle == null or castle_pos == null:
		return
	create_pawn(castle_pos)

func spawn_starting_pawns(amount: int = controller.starting_pawn_amount):
	var positions: Array = map.get_x_walkable_tiles(castle_pos, amount).keys()
	for pos in positions:
		create_pawn(pos)

func create_pawn(pos: Vector2, type: int = PAWN_TYPES.BASIC):
	var new_pawn: KinematicBody2D = get_pawn_scene(type).instance()
	new_pawn.name = "pawn" + str(pawns_created)
	pawns_created += 1
	new_pawn.player_id = player_id
	new_pawn.player_color = Network.get_color(player_id)
	new_pawn.collision_layer = physics_layer
# warning-ignore:narrowing_conversion
	new_pawn.collision_mask = pow(2, 21) - 1 - physics_layer
	new_pawn.controller = controller
	new_pawn.nav = controller.nav
	pawns.append(new_pawn)
	if not type in pawns_by_type:
		pawns_by_type[type] = []
	pawns_by_type[type].append(new_pawn)
	new_pawn.set_network_master(player_id)
# warning-ignore:return_value_discarded
	new_pawn.connect("transitioned", self, "pawn_transitioned", [new_pawn])
# warning-ignore:return_value_discarded
	new_pawn.connect("selected", self, "pawn_selected", [new_pawn])
# warning-ignore:return_value_discarded
	new_pawn.connect("deselected", self, "pawn_deselected", [new_pawn])
# warning-ignore:return_value_discarded
	new_pawn.connect("died", self, "pawn_died", [new_pawn])
	if player_id == Network.get_my_id():
# warning-ignore:return_value_discarded
		new_pawn.connect("worked",self, "pawn_worked")
	add_child(new_pawn)
	new_pawn.global_position = pos
	pawn_reserved_coords[new_pawn] = pos
	if is_network_master():
		rpc("receive_create_pawn", pos, type)

puppet func receive_create_pawn(pos: Vector2, type: int):
	#print("received create pawn")
	create_pawn(pos, type)

# warning-ignore:unused_argument
func pawn_transitioned(old_state: int, new_state: int, pawn: KinematicBody2D):
	if new_state == pawn.states.MOVING:
		pawn_reserved_coords[pawn] = pawn.get_nav_target()

func pawn_died(pawn: KinematicBody2D):
	emit_signal("pawn_died", pawn)
	rpc("receive_pawn_died", get_path_to(pawn))
	pawn.queue_free()
	remove_pawn_null_references()
	
func pawn_worked(resource):
#	update_resource(resource)
	main.update_resource(resource,1)

remote func receive_pawn_died(pawn_path: String):
	var pawn: KinematicBody2D = get_node(pawn_path)
	if pawn == null:
		return
	emit_signal("pawn_died", pawn)
	pawn.queue_free()
	remove_pawn_null_references()

func remove_pawn_null_references():
	for pawn in pawns:
		if pawn == null:
			pawns.erase(pawn)
	for type in pawns_by_type.keys():
		for pawn in pawns_by_type[type]:
			if pawn == null:
				pawns_by_type[type].erase(pawn)

func get_reserved_coords(excluded: Array = []) -> Array:
	if excluded.empty():
		return pawn_reserved_coords.values()
	var coords: Array = []
	for pawn in pawn_reserved_coords:
		if not pawn in excluded:
			coords.append(pawn_reserved_coords[pawn])
	return coords

func get_pawn_scene(type: int) -> PackedScene:
	match type:
		PAWN_TYPES.BASIC:
			return basic_pawn_scene
	return null

func get_pawns_between(pos1: Vector2, pos2: Vector2, error_margin: int = 10) -> Array:
	var list: Array = []
	var top_left: Vector2 = Vector2(min(pos1.x, pos2.x) - error_margin, min(pos1.y, pos2.y) - error_margin)
	var bot_right: Vector2 = Vector2(max(pos1.x, pos2.x) + error_margin, max(pos1.y, pos2.y) + error_margin)
	for pawn in get_children():
		var pos: Vector2 = pawn.global_position
		if pos.x < top_left.x:
			continue
		if pos.y < top_left.y:
			continue
		if pos.x > bot_right.x:
			continue
		if pos.y > bot_right.y:
			continue
		list.append(pawn)
	return list

func get_all_pawns():
	return get_children()

func pawn_selected(pawn: KinematicBody2D):
	emit_signal("pawn_selected", pawn)

func pawn_deselected(pawn: KinematicBody2D):
	emit_signal("pawn_deselected", pawn)
