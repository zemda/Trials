extends Node2D

@export var anchor_scene: PackedScene


@onready var fsm: FSM = $States
@onready var hook_target_ray: RayCast2D = $TargetRay
@onready var _rope: Line2D = $Rope

var _anchor_stack: Array[Vector2] = []
var _anchor # Vector2 or Null
var hooked: bool= false
var _parent: CharacterBody2D
var _current_anchor = null


func _ready() -> void:
	fsm.set_host(self)
	_parent = get_parent()
	_parent.player_death.connect(_on_player_death)
	_rope.visible = false


func _physics_process(_delta: float) -> void:
	if _current_anchor:
		_create_rope()


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
	_rope.points = points


func _process_wrapping() -> void:
	hook_target_ray.target_position = hook_target_ray.to_local(_anchor)
	hook_target_ray.force_raycast_update()
	if hook_target_ray.is_colliding() and \
		hook_target_ray.get_collider().is_in_group("Wrappable"):
		if (hook_target_ray.get_collision_point() - _anchor).length() < 3:
			return
		_anchor_stack.append(_anchor)
		_anchor = hook_target_ray.get_collision_point()


func _vector_alignment(vect_a: Vector2, vect_b: Vector2) -> float:
	if vect_a.length() * vect_b.length() == 0:
		return 0.0
	return vect_a.dot(vect_b) / (vect_a.length() * vect_b.length())


func _process_unwrapping() -> void:
	if not _anchor_stack:
		return
	
	hook_target_ray.target_position = hook_target_ray.to_local(_anchor)
	hook_target_ray.force_raycast_update()
	
	if hook_target_ray.is_colliding():
		if(hook_target_ray.get_collision_point() - _anchor).length() > 3:
			return
	
	hook_target_ray.target_position = hook_target_ray.to_local(_anchor_stack[-1])
	hook_target_ray.force_raycast_update()
	
	if hook_target_ray.is_colliding():
		if (hook_target_ray.get_collision_point() - _anchor_stack[-1]).length() > 3:
			return
	
	var angle_closeness = _vector_alignment(
		hook_target_ray.to_local(_anchor), 
		hook_target_ray.to_local(_anchor_stack[-1])
	)
	if angle_closeness > 0.955:
		_anchor = _anchor_stack.pop_back()


func apply_grapple_physics(delta: float) -> void:
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
		var hook_direction = sign(dir.x)
		tangential_vel = Vector2(dir.x, -dir.y) * INITIAL_SWING_SPEED * hook_direction

	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis == 0:
		input_axis = sign(dir.x)
	
	tangential_vel += Vector2(dir.x, -dir.y) * input_axis * SWING_FORCE_MULTIPLIER * delta
	var radial_accel = (DESIRED_RADIAL_SPEED - radial_vel) * RADIAL_ACCEL_FACTOR * delta
	_parent.velocity = dir * radial_vel + tangential_vel + dir * radial_accel
	_parent.velocity = _parent.velocity.clamp(-MAX_VELOCITY, MAX_VELOCITY)
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
	_rope.visible = true


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
	_rope.visible = false
	_rope.clear_points()
	_anchor_stack.clear()
	_anchor = null
	hooked = false


func is_hooked() -> bool:
	return hooked
