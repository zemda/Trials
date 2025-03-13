extends FSMState


func update(delta: float) -> void:
	host.apply_gravity(delta)
	var input_axis = Input.get_axis("move_left", "move_right")
	host.handle_acceleration(input_axis, delta)
	host.apply_friction(input_axis, delta)
	host.update_animations(input_axis)
	host.handle_downward_cast()


func _transition() -> int:
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis == 0:
		return states.IDLE
	elif Input.is_action_pressed("move_up"):
		return states.JUMP
	elif host.is_attached_to_rope:
		return states.SWINGING
	elif host.get_node("GrapplingHook").hooked:
		return states.GRAPPLING
	else:
		return states.NONE
