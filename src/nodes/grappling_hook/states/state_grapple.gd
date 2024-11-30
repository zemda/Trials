extends FSMState

var anchor: Marker2D
var anchor_stack = []
var target_ray: RayCast2D


func _enter():
	target_ray = host.get_node("TargetRay")
	anchor = Marker2D.new()
	var anchor_host: Node2D = target_ray.get_collider()
	anchor_host.add_child(anchor)
	anchor.position = anchor_host.to_local(target_ray.get_collision_point())
	$Rope.visible = true


func update(delta: float):
	_wrap()
	unwind()
	host.orbit(anchor.global_position, delta)
	host.hooked = true
	var points = [host.global_position, anchor.global_position]
	if anchor_stack:
		for a in anchor_stack:
			points.insert(2, a.global_position)
	$Rope.points = points


func _transition():
	if Input.is_action_just_released("grapple"):
		host.hooked = false
		return states.IDLE
	return states.NONE


func _exit():
	if anchor:
		anchor.queue_free()
	for a in anchor_stack:
		if a:
			a.queue_free()
	anchor_stack.clear()
	$Rope.visible = false


func create_anchor(anchor_host: Node2D, anchor_pos: Vector2) -> Marker2D:
	var new_anchor = Marker2D.new()
	anchor_host.add_child(new_anchor)
	new_anchor.position = anchor_host.to_local(anchor_pos)
	return new_anchor


func vect_angle(vect_a: Vector2, vect_b: Vector2) -> float:
	if vect_a.length() * vect_b.length() == 0:
		return 0.0
	return vect_a.dot(vect_b) / (vect_a.length() * vect_b.length())


func unwind() -> void:
	if not anchor_stack:
		return
	target_ray.target_position = host.to_local(anchor.global_position)
	target_ray.force_raycast_update()
	if target_ray.is_colliding() and (target_ray.get_collision_point() - anchor.global_position).length() > 3:
		return
	target_ray.target_position = host.to_local(anchor_stack[-1].global_position)
	target_ray.force_raycast_update()
	if target_ray.is_colliding() and (target_ray.get_collision_point() - anchor_stack[-1].global_position).length() > 3:
		return
	if vect_angle(host.to_local(anchor.global_position), host.to_local(anchor_stack[-1].global_position)) > 0.95:
		anchor.queue_free()
		anchor = anchor_stack.pop_back()


func _wrap() -> void:
	target_ray.target_position = host.to_local(anchor.global_position)
	target_ray.force_raycast_update()
	if target_ray.is_colliding():
		if (target_ray.get_collision_point() - anchor.global_position).length() < 3:
			return
		anchor_stack.append(anchor)
		anchor = create_anchor(target_ray.get_collider(), target_ray.get_collision_point())
