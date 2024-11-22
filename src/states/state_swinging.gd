extends FSMState

const CHAIN_PULL = 25
const MIN_VERTICAL_VELOCITY = 20 # TODO: BETTER solution 

const SWING_MAX_SPEED = 100.0
const SWING_ACCELERATION = 200.0
const SWING_DAMPING = 100.0


func update(delta):
	host.on_floor_override = false
	handle_swinging_input(delta)
	host.apply_gravity(delta)
	handle_jump()
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


func handle_jump():
	if host.is_on_floor_override():
		if Input.is_action_pressed("move_up"):
			host.velocity.y = -140
	else:
		if Input.is_action_just_released("move_up") and host.velocity.y < -140 / 2:
			host.velocity.y = -140 / 2.0


func handle_swinging_input(delta):
	var input_axis = Input.get_axis("move_left", "move_right")
	var rope = host.get_parent().get_node_or_null("Rope")
	
	if rope:
		var player_position = host.global_position
		var anchor_position = rope.anchor.global_position
		var rope_vector = player_position - anchor_position
		var angle = atan2(rope_vector.y, rope_vector.x)
		var desired_angle = deg_to_rad(-90)
		var angle_difference = angle - desired_angle

		if input_axis != 0:
			host.velocity.x = move_toward(host.velocity.x, SWING_MAX_SPEED * input_axis, SWING_ACCELERATION * delta)
		else:
			host.velocity.x = move_toward(host.velocity.x, 0, SWING_DAMPING * delta)
			var correction_force = -sin(angle_difference) * 30
			host.velocity.x += correction_force * delta
	else:
		host.is_attached_to_rope = false
