extends FSMState


var _knockback_force: float = 500.0
var _explosion_animation_started: bool = false


func _enter() -> void:
	_explosion_animation_started = false
	host.velocity = Vector2.ZERO


func update(_delta: float) -> void:
	if not _explosion_animation_started:
		_explode()


func _transition() -> int:
	return states.NONE


func _explode() -> void:
	_explosion_animation_started = true
	
	var direction_vector = host._player.global_position - host.global_position
	var knockback_direction: Vector2
	
	if direction_vector.length_squared() < 0.001:
		if host.velocity.x != 0:
			knockback_direction = Vector2(sign(host.velocity.x), -0.5).normalized()
		else:
			knockback_direction = Vector2(1, 0).normalized()
	else:
		knockback_direction = direction_vector.normalized()
	
	host._player.knockback(knockback_direction, _knockback_force)
	
	var tween = host.create_tween()
	tween.tween_property(host, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(host, "scale", Vector2(0.2, 0.2), 0.1)
	
	tween.tween_callback(host.queue_free)
