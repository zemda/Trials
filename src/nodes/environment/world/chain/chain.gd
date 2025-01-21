extends Node2D

@export var segment_scene: PackedScene
@export var hook: PackedScene
@export var segment_settings_resource: SegmentData
@export var hook_settings_resource: SegmentData
@export var segment_count: int = 5
@export var segment_spacing := 4.0


func _ready() -> void:
	create_rope()


func create_rope() -> void:
	var anchor_point = StaticBody2D.new()
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	
	shape.radius = 2
	col.shape = shape
	anchor_point.add_child(col)
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
		segment.mass = 0.2
		segment.linear_damp = 0.5
		segment.angular_damp = 200.0
		segment.add_to_group("Chain")
		add_child(segment)
		
		var joint = PinJoint2D.new()
		joint.softness = 0
		joint.bias = 0.2
		joint.node_a = previous_body.get_path()
		joint.node_b = segment.get_path()
		joint.position = Vector2(0, i * segment_spacing)
		add_child(joint)
		
		previous_body = segment
