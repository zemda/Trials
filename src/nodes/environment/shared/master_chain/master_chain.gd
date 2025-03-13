class_name MasterChain
extends Node2D

@export var segment_scene: PackedScene
@export var hook: PackedScene
@export var segment_settings_resource: SegmentData
@export var hook_settings_resource: SegmentData
@export var segment_count: int = 5
@export var segment_spacing := 6.0

var segments = []


func create_chain(add_hook: bool = true) -> void:
	for segment in segments:
		segment.queue_free()
	segments.clear()
	
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
	
	if add_hook:
		segment_count += 1
	
	for i in range(segment_count):
		var segment
		if i == (segment_count - 1) and add_hook:
			segment = hook.instantiate() as RigidBody2D
			segment.settings_resource = hook_settings_resource
		else:
			segment = segment_scene.instantiate() as RigidBody2D
			segment.settings_resource = segment_settings_resource
		
		segment.position = Vector2(0, i * segment_spacing)
		segments.append(segment)
		add_child(segment)
		
		var joint = PinJoint2D.new()
		joint.softness = 0
		joint.bias = 0.15
		joint.node_a = previous_body.get_path()
		joint.node_b = segment.get_path()
		segment.add_child(joint)
		
		previous_body = segment
