extends EnemyMove

var _finding_ceiling_max_tries: int = 5
var _current_tries: int = 0


func _enter() -> void:
	_current_tries = 0
	if host._original_ceiling_position != Vector2.ZERO:
		for y in range (0, 120, 15):
			var target_pos = host._original_ceiling_position + Vector2(0, y)
			if move_to(target_pos) or _current_target != NO_TARGET:
				break


func update(delta: float) -> void:
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
	
	if _current_target == NO_TARGET and _current_path.is_empty():
		if not host.find_ceiling():
			_current_tries += 1
			if _current_tries > _finding_ceiling_max_tries:
				emit_signal("transition_to", states.IDLE)


func _transition() -> int:
	if (host._player_visible or host._player_behind_wall) and host._player != null:
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		if distance_to_player < host._player_chasing_distance * 0.5:
			if randf() < 0.01:
				return states.CHASING
	
	if host._ceiling_position != Vector2.ZERO:
		return states.ATTACHING_CEILING
	
	if _current_path.size() == 0 and _current_target == NO_TARGET and host.is_on_floor():
		return states.IDLE
	
	return states.NONE
