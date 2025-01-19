extends FSMState

var _anchor: Marker2D
var _anchor_stack: Array[Marker2D] = []
var _ray_to_anchor: RayCast2D
var _rope: Line2D


func _enter() -> void:
	_ray_to_anchor = host.get_node("TargetRay")
	_anchor = Marker2D.new()
	var anchor_host: Node2D = _ray_to_anchor.get_collider()
	anchor_host.add_child(_anchor)
	_anchor.position = anchor_host.to_local(_ray_to_anchor.get_collision_point())
	_rope = $Rope
	_rope.visible = true


func update(delta: float) -> void:
	_process_wrapping()
	_process_unwrapping()
	host.apply_grapple_physics(_anchor.global_position, delta)
	host.hooked = true
	var points = [host.global_position, _anchor.global_position]
	if _anchor_stack:
		for a in _anchor_stack:
			points.insert(2, a.global_position)
	_rope.points = points


func _transition() -> int:
	if Input.is_action_just_released("grapple"):
		host.hooked = false
		return states.IDLE
	return states.NONE


func _exit() -> void:
	if _anchor:
		_anchor.queue_free()
	for a in _anchor_stack:
		if a:
			a.queue_free()
	_anchor_stack.clear()
	_rope.visible = false


func create_anchor(anchor_host: Node2D, anchor_pos: Vector2) -> Marker2D:
	var new_anchor = Marker2D.new()
	anchor_host.add_child(new_anchor)
	new_anchor.position = anchor_host.to_local(anchor_pos)
	return new_anchor


func _vector_alignment(vect_a: Vector2, vect_b: Vector2) -> float:
	if vect_a.length() * vect_b.length() == 0:
		return 0.0
	return vect_a.dot(vect_b) / (vect_a.length() * vect_b.length())


func _process_unwrapping() -> void:
	if not _anchor_stack:
		return
	
	_ray_to_anchor.target_position = host.to_local(_anchor.global_position)
	_ray_to_anchor.force_raycast_update()
	
	if _ray_to_anchor.is_colliding():
		if(_ray_to_anchor.get_collision_point() - _anchor.global_position).length() > 3:
			return
	
	_ray_to_anchor.target_position = host.to_local(_anchor_stack[-1].global_position)
	_ray_to_anchor.force_raycast_update()
	
	if _ray_to_anchor.is_colliding():
		if (_ray_to_anchor.get_collision_point() - _anchor_stack[-1].global_position).length() > 3:
			return
	
	var angle_closeness = _vector_alignment(
		host.to_local(_anchor.global_position), 
		host.to_local(_anchor_stack[-1].global_position)
	)
	if angle_closeness > 0.955:
		_anchor.queue_free()
		_anchor = _anchor_stack.pop_back()


func _process_wrapping() -> void:
	_ray_to_anchor.target_position = host.to_local(_anchor.global_position)
	_ray_to_anchor.force_raycast_update()
	if _ray_to_anchor.is_colliding():
		if (_ray_to_anchor.get_collision_point() - _anchor.global_position).length() < 3:
			return
		_anchor_stack.append(_anchor)
		_anchor = create_anchor(_ray_to_anchor.get_collider(), _ray_to_anchor.get_collision_point())
