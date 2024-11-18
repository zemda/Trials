extends Node2D

@export var segment_scene: PackedScene
@export var hook: PackedScene
@export var segment_count: int = 5
@export var segment_spacing: float = 4


func _ready():
	create_rope()

func create_rope():
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
		else:
			segment = segment_scene.instantiate() as RigidBody2D
		segment.position = Vector2(0, i * segment_spacing)
		segment.mass = 0.2
		#segment.gravity_scale = 0.25
		segment.linear_damp = 0.5
		segment.angular_damp = 200.0
		add_child(segment)
		
		var joint = PinJoint2D.new()
		joint.softness = 0
		joint.bias = 0.2
		joint.node_a = previous_body.get_path()
		joint.node_b = segment.get_path()
		joint.position = Vector2(0, i * segment_spacing)
		add_child(joint)
		
		var joint2 = DampedSpringJoint2D.new()
		joint2.stiffness = 64
		joint2.length = 1
		joint2.damping = 1
		joint2.bias = 0.9
		joint2.node_a = previous_body.get_path()
		joint2.node_b = segment.get_path()
		joint2.position = Vector2(0, i * segment_spacing)
		add_child(joint2)
		
		previous_body = segment
	
