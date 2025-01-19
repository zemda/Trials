extends RigidBody2D


func attach_to_chain(hook: Node) -> void:
	var joint = PinJoint2D.new()
	joint.node_a = hook.get_path()
	joint.node_b = get_path()
	joint.softness = 0
	joint.bias = 0.2
	add_child(joint)
	joint.position = Vector2(0.07, -1.684)


func _integrate_forces(state) -> void:
	var gravity_force = Vector2(0, 50.0)
	state.apply_central_force(gravity_force)
	
	var angle_correction = -state.transform.get_rotation() * 50
	state.apply_torque(angle_correction)
