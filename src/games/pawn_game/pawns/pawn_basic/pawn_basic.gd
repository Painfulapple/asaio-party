extends KinematicBody2D

export var speed: int = 50
export var max_health: float = 100.0
export var base_damage: float = 20
export var inaccuracy_denom: int = 15
export var debug_pawn: bool = false

onready var damage_area: Area2D = $damage_area
onready var mover: Node = $mover
onready var polygon: Polygon2D = $Polygon2D
onready var health_bar: TextureProgress = $healthbar
onready var work_bar: TextureProgress = $workbar


# pawn controller node in main scene
var controller: Node
# pawn nav node in main scene
var nav: Navigation2D

# network ID of the player who owns this pawn
var player_id: int = 0
var player_color: Color
onready var outline_color: Color = player_color.inverted()
var outline_thickness: float = 1
var pawn_type: int

var selected = false
var old_state
var mousePos:Vector2
var workProgress = 0
var state: int = states.IDLE
enum states {IDLE, MOVING, COMBAT, WORKING, HAULING}

var health: float = max_health

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
# emitted when this pawn dies lol what a loser
signal died
#emitted when finished working 
signal worked(resource)

# Called when the node enters the scene tree for the first time.
func _ready():
# warning-ignore:return_value_discarded
	mover.connect("movement_done", self, "movement_done")
# warning-ignore:return_value_discarded
	connect("selected", self, "on_selected")
# warning-ignore:return_value_discarded
	connect("deselected", self, "on_deselected")
	$damage_area.collision_layer = collision_layer
	$damage_area.collision_mask = collision_mask
	polygon.color = player_color
	update_health_bar()
	update_work_bar()

func _physics_process(delta):
	if state == states.MOVING:
		mover.move(delta)
	if state == states.WORKING: #tick up work progress value
		workProgress += delta
		update_work_bar()
		if workProgress > 10:
			print("worked")
			emit_signal("worked","Gold")
			workProgress = 0

func _process(_delta):
	health_bar.rect_rotation = -rotation_degrees
	work_bar.rect_rotation = -rotation_degrees
	damage_objects(damage_area.get_overlapping_bodies(), _delta)
#	var collision = move_and_collide(Vector2(0,0))
#	if collision == null:
#		return
#	var collider = collision.collider
#	if collider.player_id == player_id:
#		return
#	if collider.has_method("calc_damage"):
#		damage(collider.calc_damage(_delta) / 2)
#		collider.damage(calc_damage(_delta) / 2)
#	else:
#		collider.damage(calc_damage(_delta))
	#print(pawn.health)

func _draw():
	if selected:
		draw_outline()

func new_command(new_command: PawnCommand):
	command = new_command
	if command.nav_target != null:
		nav.request_path_to(command.nav_target, self)
		

func movement_done():
	if command.tileType == "Gold":
		workProgress = 0;
		transition(states.WORKING)
	else:
		transition(states.IDLE)
	
	last_command = command
	command = null

func damage_objects(objects: Array, delta: float):
	for object in objects:
		if object.player_id == player_id:
			objects.erase(object)
	if objects.empty():
		return
	var dmg: float = calc_damage(delta) / objects.size()
	for object in objects:
#		if object.has_method("calc_damage"):
#			damage(object.calc_damage(delta))
#			object.damage(dmg)
#		else:
		object.damage(dmg)

func damage(dmg: float):
	change_health(-dmg)

func calc_damage(delta: float):
	return base_damage * delta

func change_health(dif: float):
	if health == 0.0:
		return
	health += dif
	if health < 0.0:
		health = 0.0
		emit_signal("died")
	if health > max_health:
		health = max_health
	update_health_bar()

func update_health_bar():
	health_bar.value = health
	if health == max_health:
		health_bar.hide()
	else:
		health_bar.show()
		
func update_work_bar():
	work_bar.value = workProgress
	if workProgress < .1:
		work_bar.hide()
	else:
		work_bar.show()

func draw_outline():
	var poly = polygon.get_polygon()
	for i in poly.size():
		draw_line(poly[i - 1], poly[i], outline_color, outline_thickness)

func on_selected():
	#polygon.hide()
	update()
	#$Polygon2D.color = Color(0, 1, 0)

func on_deselected():
	polygon.show()
	update()
	#$Polygon2D.color = player_color

# only emitting signal allows greatest flexibility/least spaghetti code
# if we end up making more types of pawns that inherit from this script it's easier
func transition(new_state: int):
	old_state = state
	state = new_state
	if state != states.WORKING and old_state == states.WORKING:
		workProgress = 0
		update_work_bar()
	emit_signal("transitioned", old_state, new_state)

func set_selected(_selected: bool):
	selected = _selected
	if selected:
		emit_signal("selected")
	else:
		emit_signal("deselected")

func set_path(new_path):
	transition(states.MOVING)
	#print("received path: ", new_path)
	mover.path = new_path
