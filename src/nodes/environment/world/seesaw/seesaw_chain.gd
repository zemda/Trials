extends "res://nodes/environment/world/chain/chain.gd"


func create_rope() -> void: # TODO: merge segments and its gen with seesaw and chain
	var anchor_point = StaticBody2D.new()
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 2
	col.shape = shape
	anchor_point.add_child(col)
	for i in range(1, 9):
		anchor_point.set_collision_mask_value(i, 0)
		anchor_point.set_collision_layer_value(i, 0)
	add_child(anchor_point)
	
	var previous_body = anchor_point
	segment_count += 1
	
	for i in range(segment_count):
		var segment
		if i == (segment_count - 1):
			segment = hook.instantiate() as RigidBody2D
			segment.settings_resource = hook_settings_resource
		else:
			segment = segment_scene.instantiate() as RigidBody2D
			segment.settings_resource = segment_settings_resource
			
		segment.position = Vector2(0, i * segment_spacing)
		add_child(segment)
		
		var joint = PinJoint2D.new()
		joint.node_a = previous_body.get_path()
		joint.node_b = segment.get_path()
		joint.position = Vector2(0, i * segment_spacing)
		joint.softness = 0
		joint.bias = 0.01
		add_child(joint)
		
		previous_body = segment
