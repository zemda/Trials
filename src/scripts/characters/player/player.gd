extends CharacterBody2D

@export var movement_data: PlayerMovementData

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var start_pos = global_position  # TODO: later checkpoint or something
@onready var wall_jump_timer: Timer = $WallJumpTimer
@onready var fsm: FSM = $FSM

var hook_rope_velocity = Vector2.ZERO

var last_wall_normal = Vector2.ZERO
	
	
var is_attached_to_rope = false
var on_floor_override = false  # Override for animation stability with swinging rope, idk rn how much it helps tho


func _ready():
	fsm.set_host(self)
  

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not is_attached_to_rope:
			if event.pressed:
				$GrapplingHook.shoot(get_global_mouse_position())
			else:
				$GrapplingHook.release()


func is_on_floor_override() -> bool:
	return on_floor_override or is_on_floor()


func apply_gravity(delta):
	if not is_on_floor_override():
		if is_attached_to_rope:
			velocity += get_gravity() * delta * movement_data.gravity_scale * 0.3
		else:
			velocity += get_gravity() * delta * movement_data.gravity_scale


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


func apply_friction(input_axis, delta):
	if not input_axis and is_on_floor_override():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)


func apply_air_resistance(input_axis, delta):
	if not input_axis and not is_on_floor_override():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)


func handle_jump():
	if is_on_floor_override():
		if Input.is_action_pressed("move_up"):
			velocity.y = movement_data.jump_velocity
	else:
		if Input.is_action_just_released("move_up") and velocity.y < movement_data.jump_velocity / 2:
			velocity.y = movement_data.jump_velocity / 2.0


func update_animations(input_axis):
	if input_axis:
		animated_sprite_2d.flip_h = (input_axis < 0)
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	if not is_on_floor_override():
		animated_sprite_2d.play("jump")


func update_wall_state():
	var was_on_wall = is_on_wall_only()
	if was_on_wall:
		last_wall_normal = get_wall_normal()
	move_and_slide()
	var just_left_wall = was_on_wall and not is_on_wall()
	if just_left_wall:
		wall_jump_timer.start()


func _on_hazard_detector_area_entered(area: Area2D) -> void:
	global_position = start_pos  # TODO: this insta "kills" the player, later health
