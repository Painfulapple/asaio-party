extends KinematicBody2D

export var speed: int = 50
export var inaccuracy_denom: int = 15
export var debug_pawn: bool = false

onready var mover: Node = $mover

# pawn controller node in main scene
var controller: Node
# pawn nav node in main scene
var nav: Navigation2D

# network ID of the player who owns this pawn
var player_owner: int = 0

var selected = false
var old_state
var mousePos:Vector2
var state: int = states.IDLE
enum states {IDLE, MOVING, COMBAT, WORKING, HAULING}

# command the pawn is following
# some orders require multiple states (MOVING to get to tile, then WORKING to work it)
var command: PawnCommand
var last_command: PawnCommand

var path: PoolVector2Array setget set_path

# emitted when state changes
signal transitioned(old_state, new_state)
# emitted when this pawn is selected
signal selected
# emitted when this pawn is deselected
signal deselected

# Called when the node enters the scene tree for the first time.
func _ready():
	mover.connect("movement_done", self, "movement_done")
# warning-ignore:return_value_discarded
	connect("selected", self, "on_selected")
# warning-ignore:return_value_discarded
	connect("deselected", self, "on_deselected")
	#if debug_pawn:
	#	$Polygon2D.color = Color(0, 1, 0)

func _physics_process(delta):
	mover.move(delta)
#	if Input.is_action_just_pressed("left_click"):
#		if selected:
#			if not Input.is_action_pressed("left_shift"):
#				selected = false
#				emit_signal("deselected")
#		mousePos = get_global_mouse_position()

#func _unhandled_input(event):
#	if event is InputEventMouseButton and event.pressed == false and event.button_index == BUTTON_LEFT:
#		if sign(get_position().x-mousePos.x) == sign(get_global_mouse_position().x - mousePos.x) and sign(get_global_mouse_position().x-mousePos.x) == sign(get_global_mouse_position().x - get_position().x):
#			if sign(get_position().y-mousePos.y) == sign(get_global_mouse_position().y - mousePos.y) and sign(get_global_mouse_position().y-mousePos.y) == sign(get_global_mouse_position().y - get_position().y):
#				selected = true
#				emit_signal("selected")

func new_command(new_command: PawnCommand):
	command = new_command
	if command.nav_target != null:
		nav.request_path_to(command.nav_target, self)

func request_nav_to(coord: Vector2):
	pass

func movement_done():
	last_command = command
	command = null

func on_selected():
	$Polygon2D.color = Color(0, 1, 0)

func on_deselected():
	$Polygon2D.color = Color(1, 0, 0)

# only emitting signal allows greatest flexibility/least spaghetti code
# if we end up making more types of pawns that inherit from this script it's easier
func transition(new_state: int):
	old_state = state
	state = new_state
	emit_signal("transitioned", old_state, new_state)

func set_selected(selected: bool):
	selected = selected
	if selected:
		emit_signal("selected")
	else:
		emit_signal("deselected")

func set_path(new_path):
	mover.path = new_path
