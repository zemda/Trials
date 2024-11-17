extends Node2D

@export var segment_scene: PackedScene
@export var hook: PackedScene
@export var segment_count: int = 5
@export var segment_spacing: float = 4


func _ready():
	create_rope()

func create_rope():
	var anchor_point = StaticBody2D.new()
	add_child(anchor_point)
	var previous_body = anchor_point
	segment_count += 1
	for i in range(segment_count):
		var segment
		if i == (segment_count - 1):
			segment = hook.instantiate() as RigidBody2D
		else:
			segment = segment_scene.instantiate() as RigidBody2D
		segment.position = Vector2(0, i * segment_spacing)
		add_child(segment)
		
		var joint = PinJoint2D.new()
		joint.softness = 0
		joint.bias = 0.3
		joint.node_a = previous_body.get_path()
		joint.node_b = segment.get_path()
		joint.position = Vector2(0, i * segment_spacing)
		add_child(joint)
		
		previous_body = segment
	
