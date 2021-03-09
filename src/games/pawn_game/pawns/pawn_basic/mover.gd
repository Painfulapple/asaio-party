extends Node2D

export var speed: int = 50
export var inaccuracy_denom: int = 15
# relative node path to pawn root AKA kinematic body
export var pawn_path: NodePath = ".."

onready var pawn: KinematicBody2D = get_node(pawn_path)

var path: PoolVector2Array = []
var target: Vector2

var pos_dif_history: PoolIntArray

signal movement_done

func move(delta: float):
	# do target stuff -------------------------------------------
	var current_target = get_current_target()
	if current_target == null:
		emit_signal("movement_done")
		return
	target = current_target
	# look at target
	pawn.look_at(target)
	# do movement stuff -----------------------------------------
	var travel_vec: Vector2 = get_travel_vec(delta)
	# move in dir, collide and slide against anything in the way
# warning-ignore:unused_variable
	var pos_dif = pawn.move_and_slide(travel_vec)
	# if not moving and we're targeting the last point, stop trying to move
	#var is_moving: bool = check_if_moving(pos_dif)
	#if not is_moving and path.size() == 1:
	#	path = []

func get_current_target(targ: Vector2 = target, from: Vector2 = global_position):
	if path.empty():
		return null
	var current_target = path[0]
	if check_if_at_target(current_target, from):
		current_target = get_next_target(targ)
	return current_target

func get_next_target(targ: Vector2 = target):
	# if nowhere to go
	if path.empty():
		return null
	# remove current target from path if it's there
	if path[0] == targ:
		path.remove(0)
	# if nowhere to go after we remove current target
	if path.empty():
		#print("arrived at target, ", targ)
		return null
	#print(path)
	# first point in path is target
	return path[0]

func get_travel_vec(delta: float, targ: Vector2 = target, from: Vector2 = global_position) -> Vector2:
	var dir_to: Vector2 = from.direction_to(targ)
	var distance_to: float = from.distance_to(targ)
	# clamped to avoid pawn from constantly missing target
	var travel_vec: Vector2 = (dir_to * speed).clamped(distance_to / delta)
	return travel_vec

func check_if_at_target(targ: Vector2 = target, from: Vector2 = global_position) -> bool:
	return targ == from
	return (targ / inaccuracy_denom).round() == (from / inaccuracy_denom).round()

func check_if_moving(pos_dif: Vector2) -> bool:
	if pos_dif_history.size() > 4:
		pos_dif_history.remove(0)
	pos_dif_history.append(int(pos_dif.length()))
	var avg: int = avg_array(pos_dif_history)
	var is_moving: bool = avg > 5
	if pawn.debug_pawn:
		print(avg)
	return is_moving

func avg_array(array) -> int:
	var sum: int = 0
	for i in array:
		sum += i
	return sum / array.size()
