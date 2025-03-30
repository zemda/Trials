extends EnemyChasing

@export var max_chase_time: float = 10.0
@export var max_chase_distance: float = 400.0
@export var return_after_no_player_time: float = 3.0

var _chase_timer: float = 0.0
var _no_player_timer: float = 0.0


func _enter() -> void:
	super._enter()
	_chase_timer = 0.0
	_no_player_timer = 0.0


func update(delta: float) -> void:
	super.update(delta)
	
	_chase_timer += delta
	
	if not host._player_visible and not host._player_behind_wall:
		_no_player_timer += delta
	else:
		_no_player_timer = 0.0


func _transition() -> int:
	if _chase_timer >= max_chase_time:
		return states.RETURNING_TO_CEILING
	
	if host._original_ceiling_position != Vector2.ZERO:
		var distance_from_spawn = host.global_position.distance_to(host._original_ceiling_position)
		if distance_from_spawn > max_chase_distance:
			return states.RETURNING_TO_CEILING
	
	if _no_player_timer >= return_after_no_player_time:
		return states.RETURNING_TO_CEILING
	
	return super._transition()
