class_name PlayerMovementData
extends Resource

@export_range(1.0, 1000.0) var speed: float = 115.0
@export_range(-1000.0, 1000.0) var jump_velocity: float = -250.0
@export_range(1.0, 10000.0) var friction: float = 1300.0
@export_range(1.0, 10000.0) var acceleration: float = 1200.0
@export_range(0.0, 100.0) var gravity_scale: float = 1.0
@export_range(1.0, 10000.0) var air_resistance: float = 100.0
@export_range(1.0, 10000.0) var air_acceleration: float = 300.0
