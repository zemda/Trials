extends CharacterBody2D
class_name Player

signal player_death

@export var movement_data: PlayerMovementData

var last_wall_normal := Vector2.ZERO
var is_attached_to_rope := false
var _knockback_force: float = 100.0
var _knockback_velocity := Vector2.ZERO
var _is_in_knockback: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_jump_timer: Timer = $WallJumpTimer
@onready var fsm: FSM = $FSM
@onready var downward_cast: ShapeCast2D = $DownwardCast


func _ready() -> void:
	add_to_group("Player")
	fsm.set_host(self)


func _physics_process(_delta: float) -> void:
	move_and_slide()
	_update_wall_state()


func knockback(direction: Vector2, force: float = _knockback_force, should_push_up: bool = false) -> void:
	if fsm.current_state.state_name not in ["GRAPPLING", "SWINGING"]:
		fsm.change_state_to(5)
	
	_is_in_knockback = true
	var knockback_dir = direction.normalized()
	
	if is_on_floor() and should_push_up:
		knockback_dir.y = -0.8
		knockback_dir = knockback_dir.normalized()
	
	_knockback_velocity = knockback_dir * force
	var knockback_tween = create_tween()
	knockback_tween.tween_property(self, "_knockback_velocity", Vector2.ZERO, 0.2)
	knockback_tween.tween_callback(func(): _is_in_knockback = false)


func handle_downward_cast() -> void:
	downward_cast.force_shapecast_update()
	
	if downward_cast.is_colliding():
		var collision_count = downward_cast.get_collision_count()
		for i in range(collision_count):
			var collider = downward_cast.get_collider(i)
			if collider:
				var collision_point = downward_cast.get_collision_point(i)
				if collider.is_in_group("Plank"):
					_apply_force_to_plank(collider, collision_point)
				if collider.is_in_group("Chain"):
					_apply_force_to_chain_segment(collider, collision_point)


func _apply_force_to_chain_segment(segment: RigidBody2D, collision_point: Vector2) -> void:
	var player_velocity = velocity
	
	var force_direction = player_velocity.normalized()
	var speed = player_velocity.length()
	
	if speed < 80:
		speed = lerp(0, 1, speed / 80)
	else:
		speed = lerp(1, 2, (speed - 80) / (200 - 80))
	
	var force = force_direction * -500 * speed
	segment.apply_impulse(collision_point - global_position, force)


func _apply_force_to_plank(plank: RigidBody2D, collision_point: Vector2) -> void:
	var plank_center = plank.global_position
	var player_position = global_position
	
	var direction_to_player = player_position - plank_center
	if direction_to_player.y > 0: # player is not on the plank, dont apply force
		return
	
	var force = Vector2(0, -0.8)
	plank.apply_impulse(force, plank.global_position - collision_point)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if is_attached_to_rope:
			velocity += get_gravity() * delta * movement_data.gravity_scale * 0.3
		else:
			velocity += get_gravity() * delta * movement_data.gravity_scale


func handle_acceleration(input_axis: float, delta: float) -> void:
	if not is_on_floor(): 
		return
	if input_axis:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.acceleration * delta)


func handle_air_acceleration(input_axis: float, delta: float) -> void:
	if is_on_floor():
		return
	if input_axis:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.air_acceleration * delta)


func apply_friction(input_axis: float, delta: float) -> void:
	if not input_axis and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)


func apply_air_resistance(input_axis: float, delta: float) -> void:
	if not input_axis and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)


func handle_jump() -> void:
	if is_on_floor():
		if Input.is_action_pressed("move_up"):
			velocity.y = movement_data.jump_velocity
	else:
		if Input.is_action_just_released("move_up") and velocity.y < movement_data.jump_velocity / 2:
			velocity.y = movement_data.jump_velocity / 2.0


func update_animations(input_axis: float) -> void:
	if input_axis:
		update_sprite_flip(input_axis)
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	if not is_on_floor():
		animated_sprite_2d.play("jump")


func update_sprite_flip(input_axis: float) -> void:
	animated_sprite_2d.flip_h = (input_axis < 0)


func _update_wall_state() -> void:
	var was_on_wall = is_on_wall_only()
	if was_on_wall:
		last_wall_normal = get_wall_normal()
	var just_left_wall = was_on_wall and not is_on_wall()
	if just_left_wall:
		wall_jump_timer.start()


func can_grapple() -> bool:
	return not fsm.current_state.name == "state_swinging"


func _on_hazard_detector_area_entered(_area: Area2D) -> void:
	_is_in_knockback = false
	_knockback_velocity = Vector2.ZERO
	emit_signal("player_death")
