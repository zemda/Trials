class_name EnemyChasing
extends EnemyMove


func _enter() -> void:
	_path_recalculation_timer = _path_recalculation_interval


func _exit() -> void:
	_clear_path()


func update(delta: float) -> void:
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
	
	host.handle_shooting()
	
	_path_recalculation_timer += delta
	
	if host._player_visible:
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		_handle_visible_player_chasing(distance_to_player, not host.is_on_floor())
	elif host._player_behind_wall:
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		if distance_to_player <= host._player_chasing_distance:
			_handle_player_behind_wall_chasing(not host.is_on_floor())
		else:
			_handle_lost_player_chasing(not host.is_on_floor())
	else:
		_handle_lost_player_chasing(not host.is_on_floor())


func _transition() -> int:
	if not host._player_visible and not host._player_behind_wall and \
	   _current_path.size() == 0 and _current_target == NO_TARGET and \
	   host.is_on_floor():
		return states.IDLE
	
	return states.NONE
