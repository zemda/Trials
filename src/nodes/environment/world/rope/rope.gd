extends Node2D

const MINIMUM_DISTANCE = 8
const REST_CHECK_DELAY = 7

@export var segment_count: int = 5
@export var segment_spacing := 6.0
@export var segment_scene: PackedScene

var _player: CharacterBody2D = null
var _player_in_range := false
var _linked := false
var _player_detected_segments_cnt := 0
var _segments := []
var _attached_segment_index := -1
var _rest_check_timer: Timer = null
var _attaching_to_rope := false
var _attach_previous_distance := -1.0
var _attach_stuck_time := 0.0

@onready var anchor := $Anchor


func _ready() -> void:
	_generate_segments()
	_connect_segment_signals_to_rope()


func _physics_process(delta: float) -> void:
	if _attaching_to_rope:
		_smooth_attach_to_rope(delta)
		return
	
	if _linked:
		_enforce_rope_constraints()
		_handle_rope_swing_input()
		
		if Input.is_action_just_pressed("rope"):
			_unlink_player_from_rope()
			_adjust_still_rope()
		
	elif _player_in_range:
		if Input.is_action_just_pressed("rope"):
			_link_player_to_rope()
			if _rest_check_timer:
				_rest_check_timer.queue_free()
				_rest_check_timer = null


func _smooth_attach_to_rope(delta: float) -> void:
	var attached_segment = $Segments.get_child(_attached_segment_index)
	var target_position = attached_segment.global_position + Vector2(0, 15)
	var distance_to_target = _player.global_position.distance_to(target_position)
	
	# Needed in order to prevent stuck position
	if _attach_previous_distance < 0 or distance_to_target < _attach_previous_distance:
		_attach_previous_distance = distance_to_target
		_attach_stuck_time = 0.0
	else:
		_attach_stuck_time += delta
		if _attach_stuck_time > 1.0:
			_linked = false
			_player.is_attached_to_rope = false
			_adjust_still_rope()
			_attaching_to_rope = false
			_attach_previous_distance = -1.0
			_attach_stuck_time = 0.0
			return
	
	var direction_to_target = (target_position - _player.global_position).normalized()
	var max_force = 100000
	var force = direction_to_target * min(distance_to_target * 500, max_force)
	_player.velocity += force * delta

	var damping = 0.5
	_player.velocity *= pow(damping, delta * 60)

	if distance_to_target < 2:
		_player.global_position = target_position
		_player.velocity = Vector2.ZERO
		_attaching_to_rope = false


func _generate_segments() -> void:
	for segment in _segments:
		segment.queue_free()
	_segments.clear()
	
	var previous_node = anchor
	for i in range(segment_count):
		var segment = segment_scene.instantiate()
		$Segments.add_child(segment)
		_segments.append(segment)

		segment.position = Vector2(0, 3 + i * segment_spacing)

		var pin_joint = segment.get_node("PinJoint2D")
		pin_joint.node_a = segment.get_path()
		pin_joint.node_b = previous_node.get_path()
		
		previous_node = segment


func _connect_segment_signals_to_rope() -> void:
	for segment in $Segments.get_children():
		segment.connect("player_entered_segment", Callable(self, "_on_segment_player_entered"))
		segment.connect("player_exited_segment", Callable(self, "_on_segment_player_exited"))


func _link_player_to_rope() -> void:
	_attached_segment_index = _find_closest_valid_segment()
	
	if _attached_segment_index != -1:
		_player.is_attached_to_rope = true
		_linked = true
		_attaching_to_rope = true
		_apply_initial_attach_boost()


func _unlink_player_from_rope() -> void:
	_linked = false
	_player.is_attached_to_rope = false
	
	var attached_segment = $Segments.get_child(_attached_segment_index)
	var boost = Vector2(attached_segment.linear_velocity.x * 1.7, -250)
	_attached_segment_index = -1

	boost.x = clamp(boost.x, -260, 260)
	_player.velocity = Vector2.ZERO
	_player.velocity += boost


func _find_closest_valid_segment() -> int:
	if $Segments.get_child_count() <= 1:
		return -1

	var closest_distance = INF
	var closest_index = -1

	for segment_index in range(2, $Segments.get_child_count()):
		var segment = $Segments.get_child(segment_index)
		var distance = segment.global_position.distance_to(_player.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_index = segment_index

	return closest_index


func _enforce_rope_constraints() -> void:
	for segment_index in range($Segments.get_child_count() - 1, -1, -1):
		var segment = $Segments.get_child(segment_index)
		segment.linear_damp = 1
		segment.angular_damp = 1
		var next_segment = null
		if segment_index > 0:
			next_segment = $Segments.get_child(segment_index - 1)

		if next_segment:
			var distance = segment.global_position.distance_to(next_segment.global_position)
			var direction = (next_segment.global_position - segment.global_position).normalized()
			var stretch = distance - MINIMUM_DISTANCE

			# Adjust stiffness and damping based on stretch
			var stiffness = lerp(50, 800, abs(stretch) / MINIMUM_DISTANCE)
			var damping = lerp(2, 8, abs(stretch) / MINIMUM_DISTANCE)

			# Apply spring force
			var spring_force = -stiffness * stretch * direction
			segment.apply_force(spring_force, Vector2.ZERO)

			# Apply damping force
			var relative_velocity = next_segment.linear_velocity - segment.linear_velocity
			var damping_force = -damping * relative_velocity.dot(direction) * direction
			segment.apply_force(damping_force, Vector2.ZERO)


func _handle_rope_swing_input() -> void:
	if _attached_segment_index == -1:
		return
	var attached_segment = $Segments.get_child(_attached_segment_index)
	_player.global_position = attached_segment.global_position + Vector2(0,15)
	
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis != 0:
		var swing_force = Vector2(input_axis * 180000, 0)
		attached_segment.apply_force(swing_force, Vector2.ZERO)
	attached_segment.apply_torque_impulse(input_axis * 1500)


func _apply_initial_attach_boost() -> void:
	var attached_segment = $Segments.get_child(_attached_segment_index)
	if attached_segment:
		print("applying")
		attached_segment.apply_force(_player.velocity * 50000, Vector2.ZERO)


func _adjust_still_rope() -> void:
	_rest_check_timer = Timer.new()
	_rest_check_timer.wait_time = REST_CHECK_DELAY
	_rest_check_timer.one_shot = true
	_rest_check_timer.connect("timeout", Callable(self, "_on_rest_check_timer_timeout"))
	add_child(_rest_check_timer)
	_rest_check_timer.start()


func _set_segments_damping(linear_damp: float, angular_damp: float) -> void:
	for segment in $Segments.get_children():
		segment.linear_damp = linear_damp
		segment.angular_damp = angular_damp


func _on_rest_check_timer_timeout() -> void:
	_set_segments_damping(50.0, 50.0)
	_rest_check_timer.queue_free()
	_rest_check_timer = null


func _on_segment_player_entered(player_body: Node) -> void:
	if player_body.is_in_group("Player"):
		_player_detected_segments_cnt += 1
		_player_in_range = true
		_player = player_body


func _on_segment_player_exited(player_body: Node) -> void:
	if player_body.is_in_group("Player"):
		_player_detected_segments_cnt -= 1
		if _player_detected_segments_cnt == 0:
			_player_in_range = false
