extends Camera2D

var top_left_bound: Vector2 = Vector2(-1500, -900)
var bottom_right_bound: Vector2 = Vector2(1500, 900)

# storage of cam velocity, for inertial cam moving
var velocity: Vector2 = Vector2(0, 0)

var drag_pressed: bool = false

var input_rel_cache: Array = []
var input_rel_avg: Vector2 = Vector2(0, 0)

var time_since_drag: float = 0.0

func _process(delta):
	if drag_pressed:
		time_since_drag += delta
		return
	position += velocity * delta * zoom
	velocity -= velocity * 2 * delta
	clamp_pos()

func _input(input):
	if not input is InputEventMouse:
		return
	if input is InputEventMouseButton and input.button_index:
		match input.button_index:
			BUTTON_MIDDLE:
				drag_pressed = input.pressed
				if drag_pressed:
					velocity = Vector2()
				elif input_rel_avg.length() < 5 or time_since_drag > 0.1:
					velocity = Vector2(0, 0)
					return
			BUTTON_WHEEL_UP:
				zoom_view(-.1)
			BUTTON_WHEEL_DOWN:
				zoom_view(.1)

	if not input is InputEventMouseMotion:
		return
	if not drag_pressed:
		return
	
	if input_rel_cache.size() > 5:
		input_rel_cache.remove(0)
	input_rel_cache.append(input.relative)
	input_rel_avg = avg_array(input_rel_cache)
	
	velocity = -input.speed
	position -= input.relative * zoom
	time_since_drag = 0.0
	clamp_pos()

func zoom_view(amount: float):
	zoom += Vector2(1, 1) * amount
	zoom = clamp_to_bounds(zoom, Vector2(.3, .3), Vector2(5, 5))

func clamp_pos():
	global_position = clamp_to_bounds(global_position)

func clamp_to_bounds(vec: Vector2, min_bound: Vector2 = top_left_bound, max_bound: Vector2 = bottom_right_bound):
	return Vector2(clamp(vec.x, min_bound.x, max_bound.x), clamp(vec.y, min_bound.y, max_bound.y))

func avg_array(array) -> Vector2:
	var sum: Vector2 = Vector2(0, 0)
	for i in array:
		sum += i
	return sum / array.size()
