extends FSMState

var _hook_target_ray: RayCast2D


func _enter() -> void:
	_hook_target_ray = host.get_node("TargetRay")


func update(delta: float) -> void:
	var direction = (host.get_global_mouse_position() - host.global_position).normalized()
	_hook_target_ray.target_position = direction * 500
	_hook_target_ray.force_raycast_update()


func _transition() -> int:
	if Input.is_action_just_pressed("grapple"):
		if (_hook_target_ray.is_colliding() and 
			_hook_target_ray.get_collider().is_in_group("Hookable") and
			host.get_parent().can_grapple()
		):
			return states.GRAPPLE
	return states.NONE
