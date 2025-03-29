extends Camera2D

@export var teleport_threshold: float = 60.0
@export var base_smoothing_speed: float = 5.0
@export var max_smoothing_speed: float = 15.0 
@export var velocity_threshold: float = 300.0

var previous_parent_position: Vector2
var first_frame: bool = true


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = base_smoothing_speed
	
	drag_horizontal_enabled = true
	drag_vertical_enabled = true
	
	previous_parent_position = get_parent().global_position
	first_frame = true


func _physics_process(delta: float) -> void:
	var current_position = get_parent().global_position
	
	if first_frame or current_position.distance_to(previous_parent_position) > teleport_threshold:
		position_smoothing_enabled = false
		
		await get_tree().process_frame
		position_smoothing_enabled = true
		
		first_frame = false
	
	var player_velocity = get_parent().velocity
	var speed_ratio = clamp(abs(player_velocity.length()) / velocity_threshold, 0.0, 1.0)
	
	if player_velocity.y > 200:
		speed_ratio = clamp(speed_ratio * 1.5, 0.0, 1.0)
	
	position_smoothing_speed = lerp(base_smoothing_speed, max_smoothing_speed, speed_ratio)
	previous_parent_position = current_position
