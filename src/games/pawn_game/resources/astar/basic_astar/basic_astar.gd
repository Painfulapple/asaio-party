extends AStar2D

func _compute_cost(_from_id, _to_id):
	if get_point_position(_from_id).distance_to(get_point_position(_to_id)) > 1.0:
		return 0.75
	else:
		return 1.0

func _estimate_cost(_from_id, _to_id):
	if get_point_position(_from_id).distance_to(get_point_position(_to_id)) > 1.0:
		return 0.75
	else:
		return 1.0
