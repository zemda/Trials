class_name SegmentData
extends Resource

@export var collision_layer: int = 0b00000000_00000000_00000000_00000000
@export var collision_mask: int = 0b00000000_00000000_00000000_00000001
@export_range(0.0, 10000.0) var mass: float = 0.5
@export_range(0.0, 1000.0) var linear_damp: float = 0.5
@export_range(0.0, 1000.0) var angular_damp: float = 200.0
