extends FSMState

var _anchor: Marker2D
var _anchor_stack: Array[Marker2D] = []
var _rope: Line2D
var _grapple_start_time := 0.0
var _min_grapple_time := 0.2


func _enter() -> void:
	_rope = $Rope
	_rope.visible = false
	_grapple_start_time = Time.get_ticks_msec() / 1000.0
	
	var hook_data = host.get_hook_data()
	
	_anchor = Marker2D.new()
	var anchor_host: Node2D = hook_data.collider
	anchor_host.add_child(_anchor)
	_anchor.position = anchor_host.to_local(hook_data.position)
	
	_rope.visible = true
	
	var points = [host.global_position, _anchor.global_position]
	_rope.points = points


func update(delta: float) -> void:
	if not Input.is_action_pressed("grapple"):
		emit_signal("transition_to_default")
		return
		
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
	if not Input.is_action_pressed("grapple"):
		host.hooked = false
		return states.IDLE
	return states.NONE


func _exit() -> void:
	host.hooked = false
	
	_rope.visible = false
	_rope.clear_points()
	
	if _anchor and is_instance_valid(_anchor):
		_anchor.queue_free()
		_anchor = null
	
	for a in _anchor_stack:
		if a and is_instance_valid(a):
			a.queue_free()
	
	_anchor_stack.clear()
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var grapple_duration = current_time - _grapple_start_time
	
	if grapple_duration < _min_grapple_time:
		host.cleanup_current_hook()


func _create_anchor(anchor_host: Node2D, anchor_pos: Vector2) -> Marker2D:
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
	
	host.hook_target_ray.target_position = host.hook_target_ray.to_local(_anchor.global_position)
	host.hook_target_ray.force_raycast_update()
	
	if host.hook_target_ray.is_colliding():
		if(host.hook_target_ray.get_collision_point() - _anchor.global_position).length() > 3:
			return
	
	host.hook_target_ray.target_position = host.hook_target_ray.to_local(_anchor_stack[-1].global_position)
	host.hook_target_ray.force_raycast_update()
	
	if host.hook_target_ray.is_colliding():
		if (host.hook_target_ray.get_collision_point() - _anchor_stack[-1].global_position).length() > 3:
			return
	
	var angle_closeness = _vector_alignment(
		host.hook_target_ray.to_local(_anchor.global_position), 
		host.hook_target_ray.to_local(_anchor_stack[-1].global_position)
	)
	if angle_closeness > 0.955:
		_anchor.queue_free()
		_anchor = _anchor_stack.pop_back()


func _process_wrapping() -> void:
	host.hook_target_ray.target_position = host.hook_target_ray.to_local(_anchor.global_position)
	host.hook_target_ray.force_raycast_update()
	if host.hook_target_ray.is_colliding():
		if (host.hook_target_ray.get_collision_point() - _anchor.global_position).length() < 3:
			return
		_anchor_stack.append(_anchor)
		_anchor = _create_anchor(host.hook_target_ray.get_collider(), host.hook_target_ray.get_collision_point())
