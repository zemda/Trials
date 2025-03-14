extends EnemyChasing


var _explosion_distance: float = 32.0


func _transition() -> int:
	if _should_transition_to_explode():
		return states.EXPLODE
	
	return super._transition()


func _should_transition_to_explode() -> bool:
	if host._player == null or not host._player_visible:
		return false
	
	var distance_x = abs(host.global_position.x - host._player.global_position.x)
	var distance_y = abs(host.global_position.y - host._player.global_position.y)
	
	return distance_x <= _explosion_distance and distance_y <= _explosion_distance
