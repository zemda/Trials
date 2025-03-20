extends FSMState


func update(delta: float) -> void:
	host.apply_grapple_physics(delta)


func _transition() -> int:
	if not Input.is_action_pressed("grapple"):
		return states.IDLE
	return states.NONE


func _exit() -> void:
	host.cleanup_current_hook()
