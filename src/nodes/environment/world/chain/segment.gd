extends RigidBody2D


@onready var settings_resource: SegmentData


func _ready() -> void:
	if settings_resource:
		self.collision_layer = settings_resource.collision_layer
		self.collision_mask = settings_resource.collision_mask
		self.mass = settings_resource.mass
		self.linear_damp = settings_resource.linear_damp
		self.angular_damp = settings_resource.angular_damp
