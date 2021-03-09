extends Node2D

export var main_path: NodePath
export(String, FILE, "*.tres") var default_map_json = "res://games/pawn_game/maps/test_map.tres"

onready var main: Node2D = get_node(main_path)
onready var tile_resources: Dictionary = main.get_tile_resources()

# {Vector2: tile type name}
var map_tiles: Dictionary = {}
var map_tile_nodes: Dictionary = {}

var place_tile_queue: Array = []

signal tile_changed(pos, old_type, new_type)
signal tile_created(tile)
signal castle_created(tile)
signal new_nav_poly_instance(instance)

func _ready():
# warning-ignore:return_value_discarded
	main.connect("tile_placed", self, "tile_placed")
# warning-ignore:return_value_discarded
	main.connect("interaction_selected", self, "interaction_selected")

# warning-ignore:unused_argument
func _process(delta):
	for _i in 5:
		if place_tile_queue.empty():
			return
		var args: Array = place_tile_queue.pop_front()
		place_tile(args[0], args[1], args[2])

func tile_placed(pos: Vector2, type: String):
	queue_place_tile(pos, type, Network.get_my_id())
	#place_tile(pos, type, Network.get_my_id())
	rpc("receive_place_tile", pos, type, Network.get_my_id())

func queue_place_tile(pos, type, player_id):
	var args: Array = []
	args.append(pos)
	args.append(type)
	args.append(player_id)
	place_tile_queue.append(args)

func tile_destroyed(tile_node: Node2D):
	place_tile(tile_node.global_position, "Grass", 0)

func place_tile(pos: Vector2, type: String, player_id: int):
	#print("placing tile, pos: ", pos, " type: ", type)
	if not tile_resources.has(type):
		#print("tile type does not exist")
		return
	pos = round_pos(pos)
	var old_type
	if map_tiles.has(pos):
		old_type = map_tiles[pos]
	else:
		old_type = null
	if map_tile_nodes.has(pos):
		map_tile_nodes[pos].queue_free()
	map_tiles[pos] = type
	var tile = create_tile(pos, type)
	tile.player_id = player_id
	tile.connect("tile_destroyed", self, "tile_destroyed")
	map_tile_nodes[pos] = tile
	emit_signal("tile_changed", pos, old_type, type)
	emit_signal("tile_created", tile)
	if type == "Castle":
		emit_signal("castle_created", tile)
	if tile.has_node("NavigationPolygonInstance"):
		var navpoly = tile.get_node("NavigationPolygonInstance")
		emit_signal("new_nav_poly_instance", navpoly)
		navpoly.enabled = false
		navpoly.enabled = true

remote func receive_place_tile(pos: Vector2, type: String, player_id: int):
	queue_place_tile(pos, type, player_id)
	#place_tile(pos, type, player_id)

func create_tile(pos: Vector2, type: String) -> Node:
	pos = round_pos(pos)
	var new_tile: Node = tile_resources[type].gen_tile()
	#add_child(new_tile)
	call_deferred("add_child", new_tile)
	new_tile.global_position = pos
	return new_tile

func get_tile_type_group(coord: Vector2, type: String, diagonal: bool = true, excluded: Array = []) -> Dictionary:
	var tiles: Dictionary = {}
	var to_check: Array = [coord]
	while not to_check.empty():
		for vec in to_check:
			var adjacent: Dictionary = get_adjacent_tiles_of_type(vec, type, diagonal)
			for tile_coord in adjacent:
				if tile_coord in tiles:
					continue
				tiles[tile_coord] = adjacent[tile_coord]
				to_check.append(tile_coord)
			to_check.erase(vec)
	for coord in tiles:
		if coord in excluded:
# warning-ignore:return_value_discarded
			tiles.erase(coord)
	return tiles

func get_x_walkable_tiles(coord: Vector2, amount: int, diagonal: bool = false, excluded: Array = []) -> Dictionary:
	coord = round_pos(coord)
	var tiles: Dictionary = {}
	var to_check: Array = [coord]
	while tiles.size() < amount:
		var vec: Vector2 = to_check.pop_front()
		if is_tile_type_walkable(map_tiles[vec]) and not vec in excluded:
			tiles[vec] = map_tiles[vec]
		if tiles.size() == amount:
			break
		for coord in get_adjacent_walkable_tiles(vec, diagonal):
			if coord in tiles:
				continue
			to_check.append(coord)
	return tiles

func get_adjacent_tiles_of_type(coord: Vector2, type: String, diagonal: bool = false) -> Dictionary:
	var tiles: Dictionary = {}
	var adjacent: Dictionary = get_adjacent_tiles(coord, diagonal)
	for coord in adjacent:
		if adjacent[coord] == type:
			tiles[coord] = adjacent[coord]
	return tiles

func get_adjacent_walkable_tiles_of_group(tiles: Dictionary, diagonal: bool = false, excluded: Array = []) -> Dictionary:
	var walkable: Dictionary = {}
	for coord in tiles:
		var adjacent: Dictionary = get_adjacent_walkable_tiles(coord, diagonal)
		for vec in adjacent:
			#if not vec in excluded:
			walkable[vec] = adjacent[vec]
	var returned: Dictionary = {}
	for coord in walkable:
		if not coord in excluded:
			returned[coord] = walkable[coord]
	return returned

func get_adjacent_walkable_tiles(coord: Vector2, diagonal: bool = false) -> Dictionary:
	var walkable: Dictionary = {}
	var adjacent: Dictionary = get_adjacent_tiles(coord, diagonal)
	for coord in adjacent:
		if is_tile_type_walkable(adjacent[coord]):
			walkable[coord] = adjacent[coord]
	return walkable

func get_adjacent_tiles(coord: Vector2, diagonal: bool = true, include_self: bool = false) -> Dictionary:
	var tiles: Dictionary = {}
	var factors: Array = [0, 1, -1]
	for x in factors:
		for y in factors:
			if not include_self:
				if x == 0 and y == 0:
					continue
			if not diagonal:
				if x != 0 and y != 0:
					continue
			var current: Vector2 = coord + (Vector2(x, y) * 20)
			if current in map_tiles:
				tiles[current] = map_tiles[current]
	return tiles

func is_tile_type_walkable(type: String):
	return tile_resources[type].walkable

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func interaction_selected(interaction, tile):
	pass
	#var tile_coord: Vector2 = tile.global_position
	#var tile_type: String = map_tiles[tile_coord]
	#print(interaction, " ", tile_coord, " ", tile_coord in map_tiles)
	#print(get_adjacent_tiles(tile_coord))
	#print(get_adjacent_tiles_of_type(tile_coord, tile_type))
	#var group: Dictionary = get_tile_type_group(tile_coord, tile_type)
	#print(group)
	#print(get_adjacent_walkable_tiles_of_group(group))

func load_default_json():
	load_json(default_map_json)

func load_json(file_path: String):
	var file = File.new()
	file.open(file_path, File.READ)
	var json: String = file.get_as_text()
	load_from_json(json)

func load_from_json(json):
	var tile_dict = json_to_tiles(json)
	for key in tile_dict:
		queue_place_tile(key, tile_dict[key], 0)

# warning-ignore:unused_argument
func tiles_to_json(tiles: Dictionary = map_tiles) -> String:
	var json_tiles: Dictionary = {}
	for coord in map_tiles.keys():
		json_tiles[coord_to_str(coord)] = map_tiles[coord]
	var json_str: String = JSON.print(json_tiles)
	return json_str

func json_to_tiles(json: String) -> Dictionary:
	var json_tiles: Dictionary = JSON.parse(json).result
	var tile_dict: Dictionary = {}
	for str_coord in json_tiles:
		tile_dict[str_to_coord(str_coord)] = json_tiles[str_coord]
	return tile_dict

func coord_to_str(coord: Vector2) -> String:
	return str(coord.x) + "," + str(coord.y)

func str_to_coord(string: String) -> Vector2:
	var split = string.split(",")
	return Vector2(int(split[0]), int(split[1]))

func get_tile_type_at(pos: Vector2):
	pos = round_pos(pos)
	if pos in map_tiles:
		return map_tiles[pos]
	return null

func get_tile_node_at(pos: Vector2):
	pos = round_pos(pos)
	if pos in map_tile_nodes:
		return map_tile_nodes[pos]
	return null

func round_pos(pos: Vector2, step: int = 20) -> Vector2:
	return Vector2(stepify(pos.x, step), stepify(pos.y, step))
