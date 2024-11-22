extends Node2D

var anchor
var linked := false


@export var pull_factor = 7
@export var minimum_distance = 22


var player_in_range := false
var player = null


func _ready():
	link_segments_to_anchor()


func _physics_process(delta):
	if linked:
		enforce_rope_constraints(delta)
		if Input.is_action_just_pressed("rope"):
			print("unlinking")
			unlink_player()
	elif player_in_range:
		if Input.is_action_just_pressed("rope"):
			print("Linking")
			link_player_to_rope()


func link_segments_to_anchor():
	anchor = $Anchor
	var first_segment = $Segments.get_child(0)
	var first_segment_join = first_segment.get_node("PinJoint2D")
	first_segment_join.node_b = anchor.get_path()
	
	
func link_player_to_rope():
	await get_tree().process_frame
	player.is_attached_to_rope = true
	# TODO: will create new joint here
	$Player1_Joint.node_b = player.get_path()
	linked = true


func unlink_player():
	linked = false
	player.is_attached_to_rope = false
	#$Player1_Joint.queue_free() ->since cant assign null to node_b, TODO creating new joint, prolly fix this when i will generate whole rope based on segment count. also when i will use smaller segments


func enforce_rope_constraints(delta: float):
	var rope_length = $Segments.get_child_count() * minimum_distance

	var rope_vector =  player.global_position - anchor.global_position
	var current_distance = rope_vector.length()
	var direction = rope_vector.normalized()
	var distance_difference = current_distance - rope_length

	if distance_difference > 0:
		var k = 100.0
		var damping = 10.0

		var spring_force = -k * distance_difference * direction

		var relative_velocity_along_rope = player.velocity.dot(direction) * direction
		var damping_force = -damping * relative_velocity_along_rope

		var total_force = spring_force + damping_force

		player.velocity += total_force * delta


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("entered area")
		player_in_range = true
		player = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") && !linked:
		player_in_range = false
