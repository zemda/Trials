extends FSMState


func update(_delta: float) -> void:
	host.update_animations(0)
	host.move_and_slide()
	host.update_wall_state()
	host.handle_downward_cast()


func _transition() -> int:
	if not host.get_node("GrapplingHook").hooked:
		if host.is_on_floor():
			return states.IDLE
		else:
			return states.JUMP
	elif host.is_attached_to_rope:
		return states.SWINGING
	else:
		return states.NONE
