extends FSMState


func update(delta: float) -> void:
	host.apply_gravity(delta)
	host.handle_jump()
	_handle_wall_jump()
	var input_axis = Input.get_axis("move_left", "move_right")
	host.handle_air_acceleration(input_axis, delta)
	host.apply_air_resistance(input_axis, delta)
	host.update_animations(input_axis)
	host.handle_downward_cast()


func _handle_wall_jump() -> void:
	if not host.is_on_wall_only() and host.wall_jump_timer.time_left <= 0.0:
		return
	
	var wall_normal = host.get_wall_normal()
	if host.wall_jump_timer.time_left > 0:
		wall_normal = host.last_wall_normal
	
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		host.velocity.x = wall_normal.x * host.movement_data.speed / 1.7 # tweak this rng nums for better wall-jumps
		if Input.is_action_pressed("move_up"):
			host.velocity.y = host.movement_data.jump_velocity * 0.7
			if not host.jump_sound.is_playing():
				host.jump_sound.play()
		elif Input.is_action_pressed("move_down"):
			host.velocity.y = host.movement_data.jump_velocity * 0.35


func _transition() -> int:
	if host.is_on_floor():
		if not host.velocity.is_zero_approx():
			return states.RUN
		else:
			return states.IDLE
	elif host.is_attached_to_rope:
		return states.SWINGING
	elif host.get_node("GrapplingHook").hooked:
		return states.GRAPPLING
	else:
		return states.NONE
