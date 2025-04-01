extends FSMState


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
		knockback_direction = Vector2(0, -1) 
	else:
		knockback_direction = direction_vector.normalized()
		knockback_direction.y -= 0.5
		knockback_direction = knockback_direction.normalized()
	
	var knockback_force = 100.0
	
	host._player.knockback(knockback_direction, knockback_force, true)
	
	var tween = host.create_tween()
	tween.tween_property(host, "scale", Vector2(1.8, 1.8), 0.2)
	tween.tween_property(host, "scale", Vector2(0.1, 0.1), 0.1)
	tween.tween_callback(host.queue_free)
