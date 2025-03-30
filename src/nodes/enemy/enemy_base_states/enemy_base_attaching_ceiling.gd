class_name EnemyAttachingCeiling
extends FSMState


var _ready_to_attach: bool = false


func _enter() -> void:
	_ready_to_attach = false


func update(_delta: float) -> void:
	if _ready_to_attach:
		if abs(host.global_position.y - host._ceiling_position.y) < 10:
			emit_signal("transition_to", states.LURKING)
	else:
		if host.is_on_floor() and abs(host.global_position.x - host._ceiling_position.x) < 16:
			_ready_to_attach = true
			host.velocity.y = -host._jump_force * 1.2
			
			if abs(host.global_position.x - host._ceiling_position.x) > 5:
				host.velocity.x = (host._ceiling_position.x - host.global_position.x) * 3
			
			var tween = host.create_tween()
			tween.tween_property(host.get_node("Sprite2D"), "rotation_degrees", 180, 0.3)


func _exit() -> void:
	host._ceiling_position = Vector2.ZERO


func _transition() -> int:
	if host._player_visible and host._player != null:
		var distance_to_player = host.global_position.distance_to(host._player.global_position)
		if distance_to_player <= host._player_chasing_distance:
			return states.CHASING
	
	return states.NONE
