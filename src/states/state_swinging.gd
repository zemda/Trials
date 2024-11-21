extends FSMState

const CHAIN_PULL = 25
const MIN_VERTICAL_VELOCITY = 20 # TODO: BETTER solution 

const SWING_MAX_SPEED = 100.0
const SWING_ACCELERATION = 200.0

func update(delta):
	host.on_floor_override = false
	enforce_rope_constraints(delta)
	host.apply_gravity(delta)
	host.handle_jump()
	host.update_animations(0)
	host.move_and_slide()
	host.update_wall_state()

func enforce_rope_constraints(delta: float) -> void:
	await get_tree().process_frame
	var rope = host.get_parent().get_node_or_null("Rope")
	if rope:
		host.is_attached_to_rope = true
		var player_position = host.global_position
		var anchor_position = rope.anchor.global_position
		var rope_length = rope.get_node("Segments").get_child_count() * rope.minimum_distance

		var current_distance = player_position.distance_to(anchor_position)
		if current_distance > rope_length:
			var direction = (anchor_position - player_position).normalized()
			host.velocity += direction * (current_distance - rope_length) * rope.pull_factor * delta

			if abs(host.velocity.y) < MIN_VERTICAL_VELOCITY:
				host.animated_sprite_2d.play("idle")
				host.on_floor_override = true

			var pull_force = direction * (current_distance - rope_length) * CHAIN_PULL * delta
			host.velocity += pull_force

		var input_axis = Input.get_axis("move_left", "move_right")
		print(input_axis)
		if input_axis != 0:
			host.velocity.x = move_toward(host.velocity.x, SWING_MAX_SPEED * input_axis, SWING_ACCELERATION * delta)
	else:
		host.is_attached_to_rope = false

func _transition():
	print(host.is_attached_to_rope)
	if not host.is_attached_to_rope:
		if host.is_on_floor_override():
			return states.IDLE
		else:
			return states.JUMP
	else:
		return states.NONE
