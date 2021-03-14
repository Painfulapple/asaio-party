extends Navigation2D

onready var astar_nav: Node2D = $astar_nav
onready var map: Node2D = $pawn_game_map
onready var pawns = $pawn_controller

var start: Vector2 = Vector2(200, 50)
var end: Vector2 = Vector2(974, 550)

# {id: NavigationPolygonInstace}
# so we can check if the node is null (has been freed) and remove its navpoly
var nav_owners: Dictionary = {}

# stores a bunch of arrays with inputs to direct_pawn_to()
var queued_pathing: Array

const navs_per_frame: int = 5

# Called when the node enters the scene tree for the first time.
func _ready():
# warning-ignore:return_value_discarded
	map.connect("new_nav_poly_instance", self, "new_nav_poly_instance")

# warning-ignore:unused_argument
func _process(delta):
#	input()

#func _physics_process(_delta):
	if queued_pathing.empty():
		return
	for _i in navs_per_frame:
		if queued_pathing.empty():
			break
		var inputs: Array = queued_pathing.pop_front()
		callv("direct_pawn_to", inputs)

func direct_pawns_to(pos: Vector2, rand_start: bool = false):
	print("directing pawns to ", pos)
	if rand_start:
		rand_pawn_pos()
	for pawn in pawns.get_children():
		if pawn.selected:
			var pawn_pos: Vector2 = pawn.global_position
			var path: PoolVector2Array = path(pawn_pos, pos)
			pawn.path = path

# actually path should ONLY be true during _process() or _physics_process()
func direct_pawn_to(pawn: Node, pos: Vector2, actually_path: bool = false):
	if pawn == null:
		return
	if not actually_path:
		print("trying to direct pawn outside of _process(), adding to queue")
		queued_pathing.append([pawn, pos, true])
		return
	#print("navving pawn to ", pos)
	var pawn_pos: Vector2 = pawn.global_position
	var path: PoolVector2Array = path(pawn_pos, pos)
	#print(path)
	pawn.path = path

func rand_pawn_pos():
	print("randomizing pawn locations")
	for pawn in pawns.get_children():
		pawn.global_position = Vector2(rand_range(50, 974), rand_range(50, 550))

func random_path() -> PoolVector2Array:
	random()
	return path()

func path(start_coord: Vector2 = start, end_coord: Vector2 = end)-> PoolVector2Array:
	return astar_nav.path(start_coord, end_coord)
#	# offset MUST be uneven, otherwise this workaround don't werk
#	var offset: Vector2 = Vector2(0.0001, 0)
#	# adding tiny amount because for some reason you can't path to the center of a tile
#	var path: PoolVector2Array = get_simple_path(start_coord, end_coord + offset, true)
#	if path.size() > 0:
#		# subtracting that amount here to make it even once again
#		path[-1] -= offset
#	return path

func request_path_to(pos: Vector2, pawn: Node2D):
	queued_pathing.append([pawn, pos, true])

func random():
	start = Vector2(rand_range(50, 974), rand_range(50, 550))
	end = Vector2(rand_range(50, 974), rand_range(50, 550))

func update_nav_polygons():
	for id in nav_owners:
		if nav_owners[id] == null:
			navpoly_remove(id)
# warning-ignore:return_value_discarded
			nav_owners.erase(id)

func new_nav_poly_instance(instance: NavigationPolygonInstance):
	update_nav_polygons()
	var id: int = navpoly_add(instance.navpoly, instance.transform, instance)
	nav_owners[id] = instance
