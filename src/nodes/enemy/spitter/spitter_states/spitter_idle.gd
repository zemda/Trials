extends EnemyIdle


func _transition() -> int:
	if (host._player_visible or host._player_behind_wall) and host._player != null:
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		if distance_to_player <= host._player_chasing_distance:
			return states.CHASING
	
	return states.NONE
