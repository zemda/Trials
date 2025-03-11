class_name EnemyIdle
extends FSMState


var _tries_to_hang: int = 0


func _enter() -> void:
	host.velocity.x = 0


func update(delta: float) -> void:
	host.velocity.x = 0


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
