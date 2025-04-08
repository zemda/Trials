extends FSMState


func _enter() -> void:
	host.animated_sprite_2d.play("jump")


func update(delta: float) -> void:
	if host.is_dead:
		emit_signal("transition_to_default")
		return
	if host._knockback_velocity != Vector2.ZERO:
		if host.velocity.y > 0:
			host.velocity.y = 0
		host.velocity += host._knockback_velocity
		host.velocity = host.velocity.clamp(Vector2(-300, -400), Vector2(300, 300))
	
	host.apply_gravity(delta)
	host.handle_jump()
	
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis != 0:
		host.velocity.x += input_axis * host.movement_data.air_acceleration * delta * 0.5
	
	
	if host.is_on_wall_only() and Input.is_action_just_pressed("move_up"):
		var wall_normal = host.get_wall_normal()
		host.velocity.x += wall_normal.x * host.movement_data.speed
		host.velocity.y += host.movement_data.jump_velocity
	
	host.apply_air_resistance(input_axis, delta)
	host.update_animations(input_axis)
	host.handle_downward_cast()


func _transition() -> int:
	if host.is_attached_to_rope:
		return states.SWINGING
	elif host.get_node("GrapplingHook").hooked:
		return states.GRAPPLING
	
	if not host._is_in_knockback:
		if host.is_on_floor():
			if Input.get_axis("move_left", "move_right") != 0:
				return states.RUN
			else:
				return states.IDLE
		else:
			return states.JUMP
	
	return states.NONE
