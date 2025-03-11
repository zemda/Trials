class_name EnemyLurking
extends FSMState


var _player_detection_timer: float = 0.0
var _player_detection_interval: float = 0.2


func _enter() -> void:
	host._gravity_enabled = false
	host.velocity = Vector2.ZERO
	
	var tween = host.create_tween()
	tween.tween_property(host, "rotation_degrees", 180, 0.3)


func _exit() -> void:
	host._gravity_enabled = true
	host.velocity.y = 10
	
	var tween = host.create_tween()
	tween.tween_property(host, "rotation_degrees", 0, 0.3)


func update(delta: float) -> void:
	host.velocity = Vector2.ZERO
	host.handle_shooting()
	
	_player_detection_timer += delta
	if _player_detection_timer < _player_detection_interval:
		return
		
	_player_detection_timer = 0
 

func _transition() -> int:
	if host._player == null:
		return states.NONE
		
	if (host._player_behind_wall or host._player_visible):
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		if distance_to_player <= host._player_chasing_distance:
			if randf() < 0.05 * _player_detection_interval:
				return states.CHASING
	
	return states.NONE
