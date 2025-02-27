extends FSMState

func update(delta: float) -> void:
	host.move_and_slide()
	host.apply_gravity(delta)


func _transition() -> int:
	if host.is_player_in_range():
		return states.ALERT
	return states.NONE
