extends Node2D

const MINIMUM_DISTANCE = 8

@export var segment_count: int = 5
@export var segment_spacing: float = 6.0
@export var segment_scene: PackedScene

var player = null
var player_in_range := false
var linked := false
var player_detected_segments_cnt := 0
var segments = []

var rest_check_delay = 7
var rest_check_timer = null

@onready var anchor := $Anchor


func _ready():
	generate_segments()
	connect_segment_signals_to_rope()


# TODO: NEXT UPDATE - DONT LINK TO THE LAST SEGMENT BUT THE CLOSEST TO WHERE PLAYER JUMPED
# AND FIX SMOOTH ATTACHMENT TO THE ROPE
func _physics_process(delta):
	if linked:
		enforce_rope_constraints(delta)
		handle_rope_swing_input(delta)
		
		if Input.is_action_just_pressed("rope"):
			unlink_player_from_rope()
			adjust_still_rope()
		
	elif player_in_range:
		if Input.is_action_just_pressed("rope"):
			link_player_to_rope()
			if rest_check_timer:
				rest_check_timer.queue_free()
				rest_check_timer = null
			


func generate_segments():
	for segment in segments:
		segment.queue_free()
	segments.clear()
	
	var previous_node = anchor
	for i in range(segment_count):
		var segment = segment_scene.instantiate()
		$Segments.add_child(segment)
		segments.append(segment)

		segment.position = Vector2(0, 3 + i * segment_spacing)

		var pin_joint = segment.get_node("PinJoint2D")
		pin_joint.node_a = segment.get_path()
		pin_joint.node_b = previous_node.get_path()
		
		previous_node = segment


func connect_segment_signals_to_rope():
	for segment in $Segments.get_children():
		segment.connect("player_entered_segment", Callable(self, "_on_segment_player_entered"))
		segment.connect("player_exited_segment", Callable(self, "_on_segment_player_exited"))


func link_player_to_rope():
	player.is_attached_to_rope = true
	linked = true


func set_segments_damping(linear_damp, angular_damp):
	for segment in $Segments.get_children():
		segment.linear_damp = linear_damp
		segment.angular_damp = angular_damp


func unlink_player_from_rope():
	linked = false
	player.is_attached_to_rope = false
	
	var last_segment = $Segments.get_child($Segments.get_child_count() - 1)
	var boost = Vector2(last_segment.linear_velocity.x * 1.7, -250)
	player.velocity = Vector2.ZERO
	player.velocity += boost


func adjust_still_rope():
	rest_check_timer = Timer.new()
	rest_check_timer.wait_time = rest_check_delay
	rest_check_timer.one_shot = true
	rest_check_timer.connect("timeout", Callable(self, "_on_rest_check_timer_timeout"))
	add_child(rest_check_timer)
	rest_check_timer.start()


func _on_rest_check_timer_timeout():
	set_segments_damping(50, 50)
	rest_check_timer.queue_free()
	rest_check_timer = null


func enforce_rope_constraints(delta: float):
	var rope_length = $Segments.get_child_count() * MINIMUM_DISTANCE

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


func handle_rope_swing_input(delta: float):
	var last_segment = $Segments.get_child($Segments.get_child_count() - 1)
	player.global_position = last_segment.global_position + Vector2(0,20)
	
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis != 0:
		var swing_force = Vector2(input_axis * 180000, 0)
		last_segment.apply_force(swing_force, Vector2.ZERO)
	last_segment.apply_torque_impulse(input_axis * 1500)


func _on_segment_player_entered(player_body: Node):
	if player_body.is_in_group("Player"):
		player_detected_segments_cnt += 1
		player_in_range = true
		player = player_body


func _on_segment_player_exited(player_body: Node):
	if player_body.is_in_group("Player"):
		player_detected_segments_cnt -= 1
		if player_detected_segments_cnt == 0:
			player_in_range = false
