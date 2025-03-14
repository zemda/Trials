class_name EnemyWander
extends EnemyMove

var _wander_min_distance: float = 5 * 16
var _wander_max_distance: float = 20 * 16
var _wander_range_y_up: float = 10 * 16

var _spawn_position: Vector2
var _last_target_type: int = -1


func _enter() -> void:
	if _spawn_position == Vector2.ZERO:
		_spawn_position = host.global_position
	
	if host.global_position.distance_to(_spawn_position) > _wander_max_distance / 2:
		_choose_spawn_as_target()
	else:
		_choose_random_target()


func update(delta: float) -> void:
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
		
		if host.position.distance_to(_current_target) < _finish_padding and host.is_on_floor():
			_clear_path()


func _transition() -> int:
	if (host._player_visible or host._player_behind_wall) and host._player != null:
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		if distance_to_player <= host._player_chasing_distance and host.is_on_floor():
			return states.CHASING
	
	if _current_target == NO_TARGET and _current_path.size() == 0 and host.is_on_floor():
		return states.IDLE
	
	return states.NONE


func _choose_random_target() -> void:
	var target_types = [0, 1, 2]
	
	if _last_target_type >= 0:
		target_types.erase(_last_target_type)
	
	target_types.shuffle()
	
	var target_type = target_types[0]
	_last_target_type = target_type
	
	match target_type:
		0:  # Left of spawn
			if not _try_find_path_in_direction(-1):
				_choose_spawn_as_target()
		
		1:  # Return to spawn
			if not move_to(_spawn_position):
				_try_find_any_valid_path()
		
		2:  # Right of spawn
			if not _try_find_path_in_direction(1):
				_choose_spawn_as_target()


func _choose_spawn_as_target() -> void:
	if not move_to(_spawn_position):
		_try_find_any_valid_path()
	
	_last_target_type = 1


func _try_find_path_in_direction(direction: int) -> bool:
	var distance = randf_range(_wander_min_distance, _wander_max_distance)
	var target_x = _spawn_position.x + (direction * distance)
	var max_attempts = 20
	
	for i in range(max_attempts):
		var distance_factor = 1.0 - (i * 0.05)
		var test_x = lerp(_spawn_position.x, target_x, distance_factor)
		
		for j in range(5):
			var height_factor = 0
			if j > 0:
				height_factor = randf_range(0.1, 1.0)
			
			var test_y = _spawn_position.y - (_wander_range_y_up * height_factor)
			var test_position = Vector2(test_x, test_y)
			
			if move_to(test_position):
				return true
	
	return false


func _try_find_any_valid_path() -> bool:
	var directions = [-1, 1]
	directions.shuffle()
	
	for dir in directions:
		if _try_find_path_in_direction(dir):
			return true
	
	_clear_path()
	return false
