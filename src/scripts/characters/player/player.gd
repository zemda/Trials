extends CharacterBody2D

@export var movement_data : PlayerMovementData

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var start_pos = global_position # TODO: later checkpoint or something
@onready var wall_jump_timer: Timer = $WallJumpTimer

var last_wall_normal = Vector2.ZERO

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_wall_jump()
	handle_jump()
	
	var input_axis := Input.get_axis("move_left", "move_right")
	
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


func apply_gravity(delta):
	if not is_on_floor():
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
	if is_on_floor():
		if Input.is_action_just_pressed("move_up"):
			velocity.y = movement_data.jump_velocity
	else:
		if Input.is_action_just_released("move_up") and velocity.y < movement_data.jump_velocity/2:
			velocity.y = movement_data.jump_velocity / 2


func apply_friction(input_axis, delta):
	if not input_axis and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)


func apply_air_resistance(input_axis, delta):
	if not input_axis and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)


func handle_acceleration(input_axis, delta):
	if not is_on_floor(): 
		return
	if input_axis:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.acceleration * delta)


func handle_air_acceleration(input_axis, delta):
	if is_on_floor():
		return
	if input_axis:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.air_acceleration * delta)


func update_animations(input_axis):
	if input_axis:
		animated_sprite_2d.flip_h = (input_axis < 0)
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	if not is_on_floor():
		animated_sprite_2d.play("jump")


func _on_hazard_detector_area_entered(area: Area2D) -> void:
	global_position = start_pos # TODO: this insta "kills" the player, later health
