extends FSMState


func update(_delta):
	host.update_animations(0)
	host.move_and_slide()
	host.update_wall_state()


func _transition():
	if not host.get_node("GrapplingHook").hooked:
		if host.is_on_floor():
			return states.IDLE
		else:
			return states.JUMP
	elif host.is_attached_to_rope:
		return states.SWINGING
	else:
		return states.NONE
