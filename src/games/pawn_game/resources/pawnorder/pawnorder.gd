extends Resource

class_name PawnOrder

export var order_name: String
enum PLAYER_GROUPS {EVERYONE, TILE_OWNER, ENEMIES}
export(PLAYER_GROUPS) var available_for = PLAYER_GROUPS.EVERYONE
export var pawn_movement: bool = true
enum PATHING_TYPES {EDGE, CENTER, POINTER}
export(PATHING_TYPES) var pathing_type
export var use_tile_groups: bool = false
export var no_pawn_limit: bool = false
export var edge_includes_diagonal: bool = false
export var work_amount: int = 0
export var replaces_tile: bool = false
export var replacement: String = "Grass"
export var gives_item: bool = false
export var given_item: String

# world position this order was given on (where right click was)
var order_pos: Vector2
# tile node this order was given on (null if does not exist or not applicable)
var tile_node: Node2D
# pawn this order was given on (null if does not exist or not applicable)
var target_pawn: KinematicBody2D

# list of pawns this order is for
var pawns: Array = []

# list of all coords pawns should be moving towards
var pos_targets: Array = []

# pawn_controller node in main scene
var pawn_controller: Node2D
# pawn_game_map node in main scene
var pawn_game_map: Node2D

func create_commands(pawns_list: Array) -> Array:
	var commands: Array = []
	pawns = pawns_list
	var amount = pawns.size()
	if pawn_movement:
		commands = create_movement_commands(amount)
	else:
		commands = create_basic_commands(amount)
		for command in commands:
			command.look_pos = order_pos
	while commands.size() < pawns.size():
		pawns.pop_back()
	
	# assign pawns (basically random)
	for i in commands.size():
		commands[i].pawn = pawns[i]
	
	return commands

func create_movement_commands(amount: int = pawns.size()) -> Array:
	var commands: Array = []
	if pos_targets.empty():
		pos_targets = get_pos_targets(amount)
	
	# can't create commands with duplicate pos targets, shouldn't make more than we want
# warning-ignore:narrowing_conversion
	amount = min(pos_targets.size(), amount)
	var basic_commands: Array = create_basic_commands(amount)
	
	for i in amount:
		var command: PawnCommand = basic_commands.pop_back()
		command.nav_target = pos_targets[i]
		command.tileType = tile_node.type
		commands.append(command)
	
	return commands

func create_basic_commands(amount: int = pawns.size()):
	var commands: Array = []
	for i in amount:
		commands.append(create_command())
	return commands

# creates a new command resource with general data
# given more specific info in create_commands()
# assigned in pawn_controller
func create_command() -> PawnCommand:
	var command: PawnCommand = PawnCommand.new()
	command.order = self
	return command

func gen_order(pos: Vector2, tile: Node2D) -> PawnOrder:
	var order: PawnOrder = self.duplicate()
	
	order.order_pos = pos
	order.tile_node = tile
	
	return order

func get_pos_targets(amount: int = pawns.size()) -> Array:
	var targets: Array = []
	if amount == 0:
		return targets
	
	var excluded: Array = pawn_controller.get_reserved_coords(pawns)
	var rounded_pos: Vector2 = pawn_game_map.round_pos(order_pos)
	
	match pathing_type:
		PATHING_TYPES.EDGE:
			if not use_tile_groups:
				var walkable_tiles: Dictionary = pawn_game_map.get_adjacent_walkable_tiles(rounded_pos, edge_includes_diagonal)
				var walkable_coords: Array = walkable_tiles.keys()
				#var coords: Array = []
				#for i in amount:
					# if there are more pawns than walkable tiles, roll over the count
					#coords.append(walkable_coords[i % walkable_coords.size()])
				return walkable_coords#coords
			var tile_group: Dictionary = pawn_game_map.get_tile_type_group(rounded_pos, tile_node.type)
			var walkable_tiles: Dictionary = pawn_game_map.get_adjacent_walkable_tiles_of_group(tile_group, edge_includes_diagonal, excluded)
			return walkable_tiles.keys()
		PATHING_TYPES.CENTER:
			if not use_tile_groups:
				if no_pawn_limit:
					var coords: Array = []
					for i in amount:
						coords.append(rounded_pos)
					return coords
				else:
					var walkable_tiles: Dictionary = pawn_game_map.get_x_walkable_tiles(rounded_pos, amount, edge_includes_diagonal, excluded)
					return walkable_tiles.keys()
			var tile_group: Dictionary = pawn_game_map.get_tile_type_group(rounded_pos, tile_node.type, excluded)
			return tile_group.keys()
		PATHING_TYPES.POINTER:
			if not use_tile_groups:
				var coords: Array = []
				for i in amount:
					coords.append(order_pos)
				return coords
			if amount == 1:
				# return one target which is exactly where the player right clicked
				return [order_pos]
			# get walkable tiles around coord, get perfect amount for the number of pawns
			# 	this order has
			var walkable_tiles: Dictionary = pawn_game_map.get_x_walkable_tiles(rounded_pos, amount, edge_includes_diagonal, excluded)
			return walkable_tiles.keys()
	return targets

func available_for_this_client(tile_owner: int) -> bool:
	if tile_owner == 0:
		return true
	match available_for:
		PLAYER_GROUPS.EVERYONE:
			return true
		PLAYER_GROUPS.TILE_OWNER:
			return tile_owner == Network.get_my_id()
		PLAYER_GROUPS.ENEMIES:
			return tile_owner != Network.get_my_id()
	return false
