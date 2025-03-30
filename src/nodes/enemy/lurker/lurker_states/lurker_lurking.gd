extends EnemyLurking

@export var chase_chance: float = 0.02
@export var detection_distance_bonus: float = 48.0


func _enter() -> void:
	super._enter()
	if host._original_ceiling_position == Vector2.ZERO:
		host._original_ceiling_position = host.global_position


func _transition() -> int:
	if not host.can_stop_lurking:
		return states.NONE
		
	if (host._player_visible or host._player_behind_wall) and host._player != null:
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		
		if distance_to_player <= host._player_chasing_distance:
			var drop_chance = chase_chance
			if abs(host._player.global_position.x - host.global_position.x) < detection_distance_bonus and host._player.global_position.y > host.global_position.y:
				drop_chance *= 2
				
			if randf() < drop_chance * _player_detection_interval:
				return states.CHASING
	
	return states.NONE
