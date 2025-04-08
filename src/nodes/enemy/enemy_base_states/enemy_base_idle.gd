class_name EnemyIdle
extends FSMState


var _tries_to_hang: int = 0
var _idle_time_min: float = 2.0
var _idle_time_max: float = 5.0
var _idle_timer: float = 0.0
var _idle_duration: float = 0.0

var _spawn_position: Vector2

func _enter() -> void:
	host.velocity.x = 0
	if _spawn_position == Vector2.ZERO:
		_spawn_position = host.global_position
	
	_idle_timer = 0.0
	_idle_duration = randf_range(_idle_time_min, _idle_time_max)


func update(delta: float) -> void:
	host.velocity.x = 0
	_idle_timer += delta


func _transition() -> int:
	if (host._player_visible or host._player_behind_wall) and host._player != null:
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		if distance_to_player <= host._player_chasing_distance:
			return states.CHASING
	
	if _tries_to_hang < 15:
		if host.find_ceiling():
			_tries_to_hang += 1
			return states.ATTACHING_CEILING
	
	return states.NONE
