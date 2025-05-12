extends Node2D

@export var anchor_scene: PackedScene


@onready var fsm: FSM = $States
@onready var hook_target_ray: RayCast2D = $TargetRay

var _anchor_stack: Array[Vector2] = []
var _anchor
var hooked: bool = false
var _parent: CharacterBody2D
var _current_anchor = null

var _rope_points: Array = []
var _rope_visible: bool = false
var _rope_color: Color = Color(0.9, 0.9, 0.9)
var _rope_width: float = 4.0


func _ready() -> void:
	fsm.set_host(self)
	_parent = get_parent()
	_parent.player_death.connect(_on_player_death)
	_rope_visible = false


func _physics_process(_delta: float) -> void:
	if _current_anchor:
		_create_rope()


func _draw() -> void:
	if _rope_visible and _rope_points.size() > 1:
		for i in range(_rope_points.size() - 1):
			draw_line(to_local(_rope_points[i]), to_local(_rope_points[i + 1]), _rope_color, _rope_width)


func _on_player_death() -> void:
	cleanup_current_hook()
	fsm.change_state_to_default()


func _create_rope() -> void:
	if _anchor_stack.is_empty():
		_anchor = _current_anchor.global_position
	var points = [global_position, _anchor]
	_process_wrapping()
	_process_unwrapping()
	
	if _anchor_stack:
		for a in _anchor_stack:
			points.insert(2, a)
		points.append(_current_anchor.global_position)
	
	_rope_points = points
	queue_redraw()


func _process_wrapping() -> void:
	hook_target_ray.target_position = hook_target_ray.to_local(_anchor)
	hook_target_ray.force_raycast_update()
	if hook_target_ray.is_colliding() and hook_target_ray.get_collider().is_in_group("Wrappable"):
		if hook_target_ray.get_collision_point().distance_to(_anchor) < 3:
			return

		_anchor_stack.append(_anchor)
		_anchor = hook_target_ray.get_collision_point()


func _vector_alignment(vect_a: Vector2, vect_b: Vector2) -> float:
	if vect_a.is_zero_approx() or vect_b.is_zero_approx():
		return 0.0
	return vect_a.normalized().dot(vect_b.normalized())


func _process_unwrapping() -> void:
	if not _anchor_stack:
		return
	
	hook_target_ray.target_position = hook_target_ray.to_local(_anchor)
	hook_target_ray.force_raycast_update()
	
	if hook_target_ray.is_colliding():
		if hook_target_ray.get_collision_point().distance_to(_anchor) > 4:
			return
	
	hook_target_ray.target_position = hook_target_ray.to_local(_anchor_stack[-1])
	hook_target_ray.force_raycast_update()
	
	if hook_target_ray.is_colliding():
		var collision_point = hook_target_ray.get_collision_point()
		
		if collision_point.distance_to(_anchor_stack[-1]) > 4:
			return
		
		if collision_point.distance_to(_anchor_stack[-1]) <= 3 and collision_point.distance_to(_anchor) > 4:
			_anchor = _anchor_stack.pop_back()
			return

	var angle_closeness = _vector_alignment(_anchor - global_position, _anchor_stack[-1] - global_position)
	if angle_closeness > 0.96:
		_anchor = _anchor_stack.pop_back()


func apply_grapple_physics(delta: float) -> void:
	# claude help slop
	const DESIRED_RADIAL_SPEED = 400
	const RADIAL_ACCEL_FACTOR = 0.9
	const INITIAL_SWING_SPEED = 100
	const SWING_FORCE_MULTIPLIER = 70
	const MAX_VELOCITY = Vector2(200, 200)

	var to_center = _anchor - _parent.global_position
	var distance = to_center.length()
	if distance < 1:
		_parent.velocity = Vector2.ZERO
		return

	var dir = to_center / distance
	var radial_vel = _parent.velocity.dot(dir)
	var tangential_vel = _parent.velocity - dir * radial_vel

	if tangential_vel == Vector2.ZERO:
		tangential_vel = Vector2(dir.x, -dir.y) * INITIAL_SWING_SPEED
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis == 0:
		input_axis = sign(dir.x)
	tangential_vel += Vector2(dir.x, -dir.y) * input_axis * SWING_FORCE_MULTIPLIER * delta
	var radial_accel = (DESIRED_RADIAL_SPEED - radial_vel) * RADIAL_ACCEL_FACTOR * delta
	_parent.velocity = dir * radial_vel + tangential_vel + dir * radial_accel
	_parent.velocity = _parent.velocity.clamp(-MAX_VELOCITY,MAX_VELOCITY)
	_parent.move_and_slide()


func create_hook(start_pos: Vector2, target_pos: Vector2) -> void:	
	_current_anchor = anchor_scene.instantiate()
	
	var root_node = get_tree().get_root()
	root_node.add_child(_current_anchor)
	
	var aim_direction = (target_pos - start_pos).normalized()
	hook_target_ray.target_position = aim_direction * 500
	hook_target_ray.force_raycast_update()
	
	var final_target_pos
	if hook_target_ray.is_colliding():
		final_target_pos = hook_target_ray.get_collision_point()
	else:
		final_target_pos = start_pos + aim_direction * 500
	
	_current_anchor.hit_hookable.connect(_on_hit_hookable)
	_current_anchor.failed.connect(_on_hook_failed)
	
	_current_anchor.shoot(start_pos, final_target_pos)


func _on_hit_hookable(_position: Vector2, _collider: Node2D) -> void:
	hooked = true
	_rope_visible = true


func _on_hook_failed() -> void:
	_current_anchor = null


func cleanup_current_hook() -> void:
	if _current_anchor:
		if is_instance_valid(_current_anchor):
			if _current_anchor.hit_hookable.is_connected(_on_hit_hookable):
				_current_anchor.hit_hookable.disconnect(_on_hit_hookable)
			if _current_anchor.failed.is_connected(_on_hook_failed):
				_current_anchor.failed.disconnect(_on_hook_failed)
			
			_current_anchor.queue_free()
		
	_current_anchor = null
	_rope_visible = false
	_rope_points.clear()
	_anchor_stack.clear()
	_anchor = null
	hooked = false


func is_hooked() -> bool:
	return hooked
