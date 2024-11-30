extends FSMState

var target_ray: RayCast2D


func _enter():
	target_ray = host.get_node("TargetRay")


func update(delta: float):
	var direction = (host.get_global_mouse_position() - host.global_position).normalized()
	target_ray.target_position = direction * 500
	target_ray.force_raycast_update()


func _transition():
	if Input.is_action_just_pressed("grapple"):
		if target_ray.is_colliding() and target_ray.get_collider().is_in_group("Hookable"): # TODO: and player not on rope
			return states.GRAPPLE
	return states.NONE
