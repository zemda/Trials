extends Node2D

const MINIMUM_DISTANCE = 8
const REST_CHECK_DELAY = 7

@export var segment_count: int = 10
@export var segment_spacing := 6.0
@export var segment_scene: PackedScene

var _player: CharacterBody2D = null
var _player_in_range := false
var _linked := false
var _player_detected_segments_cnt := 0
var _segments := []
var _attached_segment_index := -1
var _attaching_to_rope := false
var _attach_previous_distance := -1.0
var _attach_stuck_time := 0.0

@onready var anchor := $Anchor


func _ready() -> void:
	_generate_segments()
	_connect_segment_signals_to_rope()


func _physics_process(delta: float) -> void:
	if _attaching_to_rope:
		_attach_to_rope(delta)
		return
	
	if _linked:
		_handle_rope_swing_input()
		_handle_rope_climb_input()
		
		if Input.is_action_just_pressed("rope"):
			_unlink_player_from_rope()
		
	elif _player_in_range:
		if Input.is_action_just_pressed("rope"):
			_link_player_to_rope()


func _attach_to_rope(delta: float) -> void:
	var attached_segment = $Segments.get_child(_attached_segment_index)
	var target_position = attached_segment.global_position + Vector2(0, 15)
	var distance_to_target = _player.global_position.distance_to(target_position)
	
	var direction_to_target = (target_position - _player.global_position).normalized()
	var max_force = 100000
	var force = direction_to_target * min(distance_to_target * 500, max_force)
	_player.velocity += force * delta
	_player.velocity *= pow(0.5, delta * 60)

	if distance_to_target < 2:
		_player.global_position = target_position
		_player.velocity = Vector2.ZERO
		_attaching_to_rope = false
		_attach_previous_distance = -1


func _generate_segments() -> void: # TODO: merge segments and its gen with seesaw and chain
	for segment in _segments:
		segment.queue_free()
	_segments.clear()
	
	var previous_node = anchor
	for i in range(segment_count):
		var segment = segment_scene.instantiate()
		segment.position = Vector2(0, 3 + i * segment_spacing)
		$Segments.add_child(segment)
		_segments.append(segment)
		
		var joint = PinJoint2D.new()
		joint.node_a = previous_node.get_path()
		joint.node_b = segment.get_path()
		joint.position = Vector2(0, 3 + i * segment_spacing)
		joint.softness = 0
		joint.bias = 0.1
		$Joints.add_child(joint)
		
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


func _handle_rope_swing_input() -> void:
	if _attached_segment_index == -1:
		return
	var attached_segment = $Segments.get_child(_attached_segment_index)
	_player.global_position = attached_segment.global_position + Vector2(0,15)
	
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis != 0:
		var swing_force = Vector2(input_axis * 500, 0)
		attached_segment.apply_force(swing_force, Vector2.ZERO)


func _handle_rope_climb_input() -> void: # TODO: add some slower or something
	if _attached_segment_index == -1 or not _player:
		return

	var up_down = Input.get_axis("move_up", "move_down")
	if up_down < 0.0:
		_climb_to_segment(_attached_segment_index - 1)
	elif up_down > 0.0:
		_climb_to_segment(_attached_segment_index + 1)


func _climb_to_segment(new_index: int) -> void:
	if new_index < 2 or new_index >= $Segments.get_child_count():
		return
	var seg = $Segments.get_child(new_index)
	if not seg:
		return
	_attached_segment_index = new_index


func _apply_initial_attach_boost() -> void:
	var attached_segment = $Segments.get_child(_attached_segment_index)
	if attached_segment:
		var pos = Vector2(_player.velocity.normalized().x, 0)
		var force = Vector2(_player.velocity.x * 2, 0)
		attached_segment.apply_impulse(force, pos)


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
