tool
extends Resource

class_name TileType

# editor options using export --------------------------------------------------
export (String) var type
export (String, MULTILINE) var desc
# whether or not a pawn can walk through this tile
export var walkable: bool
# whether or not this tile is destructible
export var destructible: bool
#export var health: int

# dict to store editor options added in script ---------------------------------
var editor_properties: Dictionary = {
	"interactions/interactable": "interactable", 
	"interactions/resource": "resource", 
	"interactions/work": "work", 
	"interactions/work_all_adjacent": "work_all_adjacent", 
#	"interactions/mine": "mine", 
	"interactions/deconstruct": "deconstruct", 
#	"interactions/": "", 
	
#	"commands/commandable": "commandable", 
	
	"texture/texture": "texture", 
	"texture/modulate": "modulate",
	"texture/scale": "scale"
	}

# editor options added in script -----------------------------------------------
# whether or not you can tell a pawn to interact with this tile
var interactable: bool
# what resource working this tile gives, leave blank for none
var resource: String
# available orders for pawns to carry out on this tile
var work: bool = false
var work_all_adjacent: bool = false
var deconstruct: bool = false

# stored list of enabled interactions, created at runtime
var interactions: Array = []

# whether or not you can command this tile to do something
#var commandable: bool
var texture: Texture = preload("res://games/pawn_game/map_components/tiles/common/textures/square.png")
var modulate: Color = Color(1, 1, 1, 1)
var scale: Vector2 = Vector2(4, 4)

var base_path: String = "res://games/pawn_game/map_components/tiles/tile_bases/base/base.tscn"
var base_scene: PackedScene = load(base_path)

var interact_area_path: String = "res://games/pawn_game/map_components/tiles/tile_components/interact_area/interact_area.tscn"
var interact_area_scene: PackedScene = load(interact_area_path)

var navpoly_path: String = "res://games/pawn_game/map_components/tiles/tile_components/navpoly/navpoly.tscn"
var navpoly_scene: PackedScene = load(navpoly_path)

var tile_node: Node
var sprite_node: Sprite

func gen_tile():
	if tile_node == null:
		var tile: Node = base_scene.instance()
		if walkable:
			tile.add_child(navpoly_scene.instance())
		if interactable:
			tile.add_child(interact_area_scene.instance())
		tile.add_child(gen_sprite(1.0, -5))
		tile_node = tile
		#tile_node.init_tile(gen_tile_data())
	var tile: Node = tile_node.duplicate()
	tile.init_tile(gen_tile_data())
	return tile

func gen_sprite(alpha: float = 0.5, z_index: int = 0):
	if sprite_node == null:
		var sprite: Sprite = Sprite.new()
		sprite.texture = texture
		sprite.modulate = modulate
		sprite.modulate.a = alpha
		sprite.scale = scale
		sprite.z_index = z_index
		sprite_node = sprite
	var sprite = sprite_node.duplicate()
	sprite.modulate.a = alpha
	return sprite
#	var sprite: Sprite = Sprite.new()
#	sprite.texture = texture
#	sprite.modulate = modulate
#	sprite.modulate.a = alpha
#	sprite.scale = scale
#	return sprite

func gen_tile_data() -> Dictionary:
	var tile_data: Dictionary = {}
	interactions = []
	for property in ["work", "work_all_adjacent", "deconstruct"]:
		if get(property):
			interactions.append(property)
	#print(type, " ", interactions)
	for property in ["type", "desc", "walkable", "destructible", "health", "interactable", "resource", "interactions"]:
		tile_data[property] = get(property)
	return tile_data

func _set(property, value):
	if editor_properties.has(property):
		set(editor_properties[property], value)

func _get(property):
	if editor_properties.has(property):
		return get(editor_properties[property])

func _get_property_list():
	var property_list: Array = []
	for property in editor_properties:
		var entry: Dictionary = {}
# warning-ignore:shadowed_variable
		var type: int = typeof(get(editor_properties[property]))
		if type == TYPE_OBJECT:
			var property_class: String = get(editor_properties[property]).get_class()
			if ClassDB.instance(property_class) is Texture:
				property_class = "Texture"
			entry["hint"] = PROPERTY_HINT_RESOURCE_TYPE
			entry["hint_string"] = property_class
		entry["name"] = property
		entry["type"] = type
		property_list.append(entry)
	return property_list
