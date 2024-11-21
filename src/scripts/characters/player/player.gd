extends CharacterBody2D

@export var movement_data : PlayerMovementData

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var start_pos = global_position # TODO: later checkpoint or something
@onready var wall_jump_timer: Timer = $WallJumpTimer

const CHAIN_PULL = 25
const SWING_DAMPING = 0.9
const MIN_VERTICAL_VELOCITY = 20 # TODO too much, it will switch to idle anim in the middle of air
const SWING_FORCE_SCALE = 0.5 # TODO: not working, add fsm

var chain_velocity = Vector2.ZERO
var custom_velocity = Vector2.ZERO

var last_wall_normal = Vector2.ZERO

var is_attached_to_rope := true # later false, make it as a event
var on_floor_override := false  # Override for animation stability


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			$GrapplingHook.shoot(get_global_mouse_position())
		else:
			$GrapplingHook.release()
	#if event.is_action_pressed("rope") or event.is_action_released("rope"):
		#is_attached_to_rope = not is_attached_to_rope


func _physics_process(delta: float) -> void:
	on_floor_override = false
	if is_attached_to_rope:
		enforce_rope_constraints(delta)
		
	apply_gravity(delta)
	handle_wall_jump()
	handle_jump()
	var input_axis := Input.get_axis("move_left", "move_right")
	
	handle_grappling_hook(input_axis)
	
	handle_acceleration(input_axis, delta)
	handle_air_acceleration(input_axis, delta)
	apply_friction(input_axis, delta)
	apply_air_resistance(input_axis, delta)
	
	update_animations(input_axis)
	
	var was_on_wall = is_on_wall_only()
	if was_on_wall:
		last_wall_normal = get_wall_normal()
	move_and_slide()
	var just_left_wall = was_on_wall and not is_on_wall()
	if just_left_wall:
		wall_jump_timer.start()


func enforce_rope_constraints(delta: float) -> void:
	await get_tree().process_frame
	var rope = get_parent().get_node_or_null("Rope")
	if rope:
		var player_position = global_position
		var anchor_position = rope.anchor.global_position
		var rope_length = rope.get_node("Segments").get_child_count() * rope.minimum_distance

		var current_distance = player_position.distance_to(anchor_position)
		if current_distance > rope_length:
			var direction = (anchor_position - player_position).normalized()
			velocity += direction * (current_distance - rope_length) * rope.pull_factor * delta

			# TODO - try to fix on floor flickering when attached to a rope, this is ew
			print("My on floor: ", on_floor_override, ", engine: ", is_on_floor(), ", velocity y: ", abs(velocity.y))
			if abs(velocity.y) < MIN_VERTICAL_VELOCITY:
				animated_sprite_2d.play("idle")
				on_floor_override = true

			var pull_force = direction * (current_distance - rope_length) * CHAIN_PULL * delta
			velocity += pull_force

		# TODO: dampen swinging force, prolly FSM
		var input_axis = Input.get_axis("move_left", "move_right")
		if input_axis != 0:
			var swing_direction = Vector2(-input_axis, 0).normalized()
			velocity += swing_direction * SWING_FORCE_SCALE * delta


func is_on_floor_override() -> bool:
	return on_floor_override or is_on_floor()


func handle_grappling_hook(input_axis) -> void:
	if $GrapplingHook.hooked:
		print("Hooked")
		var direction_to_anchor = ($GrapplingHook.tip_position - global_position).normalized()
		chain_velocity = direction_to_anchor * CHAIN_PULL
		print("Vel: ", chain_velocity)
		if chain_velocity.y > 0:
			chain_velocity.y *= 0.55
		else:
			chain_velocity.y *= 1.65
		if sign(chain_velocity.x) != sign(input_axis):
			chain_velocity.x *= 0.7
	else:
		chain_velocity = Vector2.ZERO
	velocity += chain_velocity


func apply_gravity(delta):
	if not is_on_floor_override():
		velocity += get_gravity() * delta * movement_data.gravity_scale


func handle_wall_jump():
	if not is_on_wall_only() and wall_jump_timer.time_left <= 0.0:
		return
	
	var wall_normal = get_wall_normal()
	if wall_jump_timer.time_left > 0:
		wall_normal = last_wall_normal
	
	if ((Input.is_action_just_pressed("move_left")) or 
		(Input.is_action_just_pressed("move_right"))
		) :
			velocity.x = wall_normal.x * movement_data.speed / 2
			if Input.is_action_pressed("move_up"):
				velocity.y = movement_data.jump_velocity * 0.7
			elif Input.is_action_pressed("move_down"): # TODO: when falling down deal dmg to player, with this he can counter it
				velocity.y = movement_data.jump_velocity * 0.1


func handle_jump():
	if is_on_floor_override():
		if Input.is_action_just_pressed("move_up"):
			velocity.y = movement_data.jump_velocity
	else:
		if Input.is_action_just_released("move_up") and velocity.y < movement_data.jump_velocity/2:
			velocity.y = movement_data.jump_velocity / 2


func apply_friction(input_axis, delta):
	if not input_axis and is_on_floor_override():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)


func apply_air_resistance(input_axis, delta):
	if not input_axis and not is_on_floor_override():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)


func handle_acceleration(input_axis, delta):
	if not is_on_floor_override(): 
		return
	if input_axis:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.acceleration * delta)


func handle_air_acceleration(input_axis, delta):
	if is_on_floor_override():
		return
	if input_axis:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.air_acceleration * delta)


func update_animations(input_axis):
	if input_axis:
		animated_sprite_2d.flip_h = (input_axis < 0)
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	if not is_on_floor_override():
		animated_sprite_2d.play("jump")


func _on_hazard_detector_area_entered(area: Area2D) -> void:
	global_position = start_pos # TODO: this insta "kills" the player, later health
