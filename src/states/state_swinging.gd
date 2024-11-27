extends FSMState

const CHAIN_PULL = 25
const MIN_VERTICAL_VELOCITY = 20 # TODO: BETTER solution 

const SWING_MAX_SPEED = 100.0
const SWING_ACCELERATION = 200.0
const SWING_DAMPING = 100.0


func update(delta):
	host.on_floor_override = false
	host.apply_gravity(delta)
	host.update_animations(0)
	host.move_and_slide()
	host.update_wall_state()


func _transition():
	if not host.is_attached_to_rope:
		if host.is_on_floor_override():
			return states.IDLE
		else:
			return states.JUMP
	else:
		return states.NONE
