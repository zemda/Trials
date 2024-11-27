extends FSMState

const CHAIN_PULL = 20

func update(delta):
	host.on_floor_override = false
	handle_grappling_hook(delta)
	host.apply_gravity(delta)
	host.update_animations(0)
	host.handle_jump()
	host.move_and_slide()
	host.update_wall_state()


func handle_grappling_hook(delta):
	var input_axis = Input.get_axis("move_left", "move_right")
	if host.get_node("GrapplingHook").hooked:
		var direction_to_anchor = (host.get_node("GrapplingHook").tip_position - host.global_position).normalized()
		host.hook_rope_velocity = direction_to_anchor * CHAIN_PULL
		if host.hook_rope_velocity.y > 0:
			host.hook_rope_velocity.y *= 0.55
		else:
			host.hook_rope_velocity.y *= 1.5
		if sign(host.hook_rope_velocity.x) != sign(input_axis):
			host.hook_rope_velocity.x *= 0.7
	else:
		host.hook_rope_velocity = Vector2.ZERO
	host.velocity += host.hook_rope_velocity


func _transition():
	if not host.get_node("GrapplingHook").hooked:
		if host.is_on_floor_override():
			return states.IDLE
		else:
			return states.JUMP
	elif host.is_attached_to_rope:
		return states.SWINGING
	else:
		return states.NONE
