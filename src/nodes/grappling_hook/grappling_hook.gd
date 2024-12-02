extends Node2D

var hooked := false

var _parent: CharacterBody2D

@onready var fsm = $States

func _ready() -> void:
	fsm.set_host(self)
	_parent = get_parent()


func apply_grapple_physics(center: Vector2, delta: float) -> void:
	const DESIRED_RADIAL_SPEED = 400
	const RADIAL_ACCEL_FACTOR = 0.9
	const INITIAL_SWING_SPEED = 100
	const SWING_FORCE_MULTIPLIER = 70
	const MAX_VELOCITY = Vector2(200, 200)

	var to_center = center - _parent.global_position
	var distance = to_center.length()
	if distance < 1: # TODO: do this smarter, since this doesnt account players size, corners, and so on... 
		_parent.velocity = Vector2.ZERO
		return

	var dir = to_center / distance
	var radial_vel = _parent.velocity.dot(dir)
	var tangential_vel = _parent.velocity - dir * radial_vel

	if tangential_vel == Vector2.ZERO:
		tangential_vel = Vector2(dir.x, -dir.y) * INITIAL_SWING_SPEED

	tangential_vel += Vector2(dir.x, -dir.y) * Input.get_axis("move_left", "move_right") * SWING_FORCE_MULTIPLIER * delta
	var radial_accel = (DESIRED_RADIAL_SPEED - radial_vel) * RADIAL_ACCEL_FACTOR * delta
	_parent.velocity = dir * radial_vel + tangential_vel + dir * radial_accel
	_parent.velocity = _parent.velocity.clamp(-MAX_VELOCITY,MAX_VELOCITY)
	_parent.move_and_slide()
