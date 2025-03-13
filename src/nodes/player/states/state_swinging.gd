extends FSMState


func update(delta: float) -> void:
	host.apply_gravity(delta)
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis:
		host.update_sprite_flip(input_axis)
	host.update_animations(0)


func _transition() -> int:
	if not host.is_attached_to_rope:
		if host.is_on_floor():
			return states.IDLE
		else:
			return states.JUMP
	else:
		return states.NONE
