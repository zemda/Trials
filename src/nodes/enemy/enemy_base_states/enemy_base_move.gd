class_name EnemyMove
extends FSMState


@export var chasing_threshold: float = 130

const NO_TARGET: Vector2 = Vector2(-9999999, -9999999)

var _current_path: Array = []
var _current_target: Vector2 = NO_TARGET
var _go_to_position: Vector2 = NO_TARGET

var _padding: float = 2.5
var _finish_padding: float = 5.0
var _stuck_timer: float = 0.0
var _stuck_timeout: float = 0.5

var _path_recalculation_timer: float = 0.0
var _path_recalculation_interval: float = 0.5


func _handle_visible_player_chasing(distance_to_player: float, is_mid_jump: bool) -> void:
	if distance_to_player > chasing_threshold:
		_chase_if_path_needs_recalculation(is_mid_jump)
	else:
		if not is_mid_jump:
			_clear_path()


func _handle_player_behind_wall_chasing(is_mid_jump: bool) -> void:
	_chase_if_path_needs_recalculation(is_mid_jump)


func _handle_lost_player_chasing(is_mid_jump: bool) -> void:
	if host._player_last_known_position != NO_TARGET:
		_chase_last_known_position(is_mid_jump)


func _chase_if_path_needs_recalculation(is_mid_jump: bool) -> void:
	if (not is_mid_jump) and (_current_target == NO_TARGET or _current_path.size() < 2):
		if _path_recalculation_timer >= _path_recalculation_interval:
			move_to(host._player.global_position)
			_path_recalculation_timer = 0.0


func _chase_last_known_position(is_mid_jump: bool) -> void:    
	if not is_mid_jump and _go_to_position != host._player_last_known_position:
		move_to(host._player_last_known_position)
	
	if abs(host._player_last_known_position.x - host.position.x) < _padding or \
			_current_target == NO_TARGET or _current_path.size() == 0:
		host._player_last_known_position = NO_TARGET


func _move_towards_target() -> void:
	if _current_target == NO_TARGET:
		host.velocity.x = 0
		return
	
	if (_current_target.x - _padding > host.position.x):
		host.velocity.x = host._speed
	elif (_current_target.x + _padding < host.position.x):
		host.velocity.x = -host._speed
	else:
		host.velocity.x = 0
	
	if host.position.distance_to(_current_target) < _finish_padding and host.is_on_floor():
		_next_point()
		_stuck_timer = 0


func _next_point() -> void:
	if _current_path.size() == 0:
		_current_target = NO_TARGET
		return
	
	var next_node = _current_path.pop_front()
	
	if next_node == null:
		_current_target = NO_TARGET
		return
		
	if next_node.get("type", "move") == "jump":
		if host.is_on_floor():
			var jump_force = next_node.get("jump_force", 380)
			host.velocity.y = -jump_force
	
	_current_target = next_node.position


func _check_if_stuck(delta: float) -> void:
	if _current_path.size() > 0 and abs(host.velocity.x) < 10.0 and host.is_on_floor():
		_stuck_timer += delta
		if _stuck_timer > _stuck_timeout:
			_recalculate_path()
			_stuck_timer = 0
	else:
		_stuck_timer = 0


func _clear_path() -> void:
	_current_target = NO_TARGET
	_current_path.clear()
	_go_to_position = NO_TARGET
	host.velocity = Vector2.ZERO
	_stuck_timer = 0


func _recalculate_path() -> void:
	if _go_to_position != NO_TARGET and host._path_finder:
		var new_path = host._path_finder.find_path(
			host.global_position,
			_go_to_position,
			host.player_width,
			host.player_height
		)
		
		if new_path.size() > 0:
			_current_path = new_path
			_next_point()
		else:
			_clear_path()


func move_to(destination: Vector2) -> bool:
	if not host.is_on_floor() and _current_path.size() > 0:
		return false
		
	_current_path.clear()
	_current_target = NO_TARGET
	_stuck_timer = 0
	
	if host._path_finder:
		_go_to_position = destination
		var new_path = host._path_finder.find_path(
			host.global_position,
			destination,
			host.player_width,
			host.player_height
		)

		if new_path.size() > 0:
			_current_path = new_path
			_next_point()
			return true
		else:
			_go_to_position = NO_TARGET
	return false
