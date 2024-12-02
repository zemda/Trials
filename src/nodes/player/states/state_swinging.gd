extends FSMState


func update(delta: float) -> void:
	host.apply_gravity(delta)
	host.update_animations(0)
	host.move_and_slide()
	host.update_wall_state()


func _transition() -> int:
	if not host.is_attached_to_rope:
		if host.is_on_floor():
			return states.IDLE
		else:
			return states.JUMP
	else:
		return states.NONE
