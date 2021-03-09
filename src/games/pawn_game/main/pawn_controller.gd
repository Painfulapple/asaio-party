extends Node2D

#export(String, FILE) var pawn_scene_path

onready var main: Node2D = get_parent().get_parent()
onready var nav: Navigation2D = get_parent()
onready var map: Node2D = get_node("../pawn_game_map")
#onready var pawn_scene: PackedScene = load(pawn_scene_path)

export var starting_pawn_amount: int = 25

var player_pawn_manager_scene: PackedScene = load("res://games/pawn_game/main/player_pawn_manager/player_pawn_manager.tscn")

var selected_pawns: Array = []

# storage of coords not to path pawns to, nodes keyed by coord
var reserved_coords: Dictionary = {}

# coords pawns are chillin in, nodes keyed by coord
var occupied_coords: Dictionary = {}

puppet var player_physics_layers: Dictionary = {}

# player pawn managers keyed by network ID
var managers: Dictionary = {}

var health_sync_delay: float = 1.0
var time_since_health_sync: float = 0.0

signal my_castle_created
#signal command_issued(command_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	$player_pawn_manager.queue_free()
# warning-ignore:return_value_discarded
	main.connect("interaction_selected", self, "interaction_selected")
# warning-ignore:return_value_discarded
	main.connect("new_order", self, "new_order")
# warning-ignore:return_value_discarded
	main.connect("box_selection_completed", self, "box_selection_completed")
	var peers: Array = Network.get_peers()
	for i in peers.size():
		# adding 1 so pawns aren't on physics layer used for walls/environment
		player_physics_layers[peers[i]] = pow(2, i + 1)
	print(player_physics_layers)
	if is_network_master():
		rset("player_physics_layers", player_physics_layers)
		rpc("create_pawn_managers", player_physics_layers)

func process(delta):
	if not get_tree().is_network_server():
		return
	time_since_health_sync += delta
	if time_since_health_sync > health_sync_delay:
		sync_pawn_health()
		time_since_health_sync = 0.0

func sync_pawn_health():
	if not get_tree().is_network_server():
		return
	var pawns: Array = []
	for manager in managers.values():
		pawns += manager.get_all_pawns()
	var pawn_health: Dictionary = {}
	for pawn in pawns:
		pawn_health[get_path_to(pawn)] = pawn.health
	rpc("receive_pawn_health", pawn_health)

puppet func receive_pawn_health(pawn_health: Dictionary):
	for path in pawn_health:
		var pawn = get_node_or_null(path)
		if pawn == null:
			continue
		pawn.health = pawn_health[path]

# for when a new order comes in locally AKA from this client
func new_order(order: PawnOrder, pawns: Array = selected_pawns.duplicate()):
	for pawn in selected_pawns:
		if pawn == null:
			selected_pawns.erase(pawn)
	for pawn in pawns:
		if pawn == null:
			pawns.erase(pawn)
	init_order(order, pawns)
	send_order(order, pawns)

# generally initiates orders (gives order info to create commands + issues commands to pawns)
# both for orders created locally and received remotely
func init_order(order: PawnOrder, pawns: Array):
	order.pawn_controller = self
	order.pawn_game_map = map
	for pawn in pawns:
		if pawn == null:
			pawns.erase(pawn)
			continue
	#print(pawns)
	var commands: Array = order.create_commands(pawns.duplicate())
	#print(commands)
	print("assigning commands")
	for command in commands:
		issue_command(command.pawn, command)

func send_order(order: PawnOrder, pawns: Array):
	var order_data: Dictionary = {}
	var properties: Array = ["order_name", "pawn_movement", "pathing_type", "use_tile_groups", "work_amount", "replaces_tile", "replacement", "gives_item", "given_item", "order_pos", "pos_targets"]
	for prop in properties:
		order_data[prop] = order.get(prop)
	var pawn_paths: Array = []
	for pawn in pawns:
		pawn_paths.append(get_path_to(pawn))
	print("sending order, data: ", order_data, "pawn paths: ", pawn_paths)
	rpc("receive_order", order_data, pawn_paths)

remote func receive_order(order_data: Dictionary, pawn_paths: Array):
	print("received order, data: ", order_data, "pawn paths: ", pawn_paths)
	var order: PawnOrder = PawnOrder.new()
	for prop in ["order_name", "pawn_movement", "pathing_type", "use_tile_groups", "work_amount", "replaces_tile", "replacement", "gives_item", "given_item", "order_pos", "pos_targets"]:
		order.set(prop, order_data[prop])
	order.tile_node = map.get_tile_node_at(order.order_pos)
	var pawns: Array = []
	for path in pawn_paths:
		#print(path == "")
		if path == "":
			continue
		var pawn = get_node_or_null(path)
		# if pawn is dead or otherwise doesn't exist skip this iteration
		# 	avoids crash caused by loser pawns dying
		if pawn == null:
			continue
		pawns.append(pawn)
	init_order(order, pawns)

func get_reserved_coords(excluded: Array = []) -> Array:
	# only gets tiles reserved by your pawns because you will just fight enemy ones
	return get_my_manager().get_reserved_coords(excluded)
#	var reserved: Array = []
#	for manager in managers.values():
#		reserved += manager.get_reserved_coords(excluded)
#	return reserved

func issue_command(pawn: KinematicBody2D, command: PawnCommand):
	# if pawn don't exist
	if pawn == null:
		return
	pawn.new_command(command)

func box_selection_completed(start: Vector2, end: Vector2):
	if not Input.is_action_pressed("left_shift"):
		deselect_all_pawns()
	var pawns: Array = get_pawns_between(start, end)
	select_pawns(pawns)

func select_pawns(pawns: Array):
	for pawn in pawns:
		pawn.set_selected(true)

func deselect_all_pawns():
	deselect_pawns(get_my_pawns())

func deselect_pawns(pawns: Array):
	for pawn in pawns:
		pawn.set_selected(false)

func get_pawns_between(pos1: Vector2, pos2: Vector2, error_margin: int = 10) -> Array:
	return get_my_manager().get_pawns_between(pos1, pos2, error_margin)

puppetsync func create_pawn_managers(physics_layers: Dictionary = player_physics_layers):
	for player_id in physics_layers.keys():
		var manager: Node2D = player_pawn_manager_scene.instance()
		manager.name = str(player_id)
		manager.map = map
		manager.player_id = player_id
		manager.physics_layer = physics_layers[player_id]
# warning-ignore:return_value_discarded
		manager.connect("pawn_selected", self, "pawn_selected")
# warning-ignore:return_value_discarded
		manager.connect("pawn_deselected", self, "pawn_deselected")
# warning-ignore:return_value_discarded
		manager.connect("pawn_died", self, "pawn_died")
# warning-ignore:return_value_discarded
		manager.connect("my_castle_created", self, "my_castle_created")
		managers[player_id] = manager
		add_child(manager)

func get_my_pawns() -> Array:
	return get_my_manager().get_all_pawns()

func get_my_manager():
	return managers[Network.get_my_id()]

func pawn_selected(pawn: Node):
	#print("pawn selected: ", pawn)
	selected_pawns.append(pawn)
	#print(selected_pawns)

func pawn_deselected(pawn: Node):
	#print("pawn deselected: ", pawn)
# warning-ignore:return_value_discarded
	selected_pawns.erase(pawn)

func pawn_died(pawn: Node):
	selected_pawns.erase(pawn)

func my_castle_created():
	emit_signal("my_castle_created")
