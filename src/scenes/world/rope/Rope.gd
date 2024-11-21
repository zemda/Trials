extends Node2D

var player
var anchor
var linked := false


@export var pull_factor = 5
@export var minimum_distance = 15


func _ready():
	link_player_to_anchor()

func _physics_process(delta):
	if linked:
		enforce_rope_constraints(delta)

func link_player_to_anchor():
	await get_tree().process_frame
	
	player = get_parent().get_node("Player")
	anchor = $Anchor
	
	# connect player to the last segment
	$Player1_Joint.node_b = player.get_path()
	
	# connect anchor
	var first_segment = $Segments.get_child(0)
	var first_segment_join = first_segment.get_node("PinJoint2D")
	first_segment_join.node_b = anchor.get_path()
	
	linked = true

func enforce_rope_constraints(delta: float):
	var player_position = player.global_position
	var anchor_position = anchor.global_position
	var rope_length = $Segments.get_child_count() * minimum_distance

	var current_distance = player_position.distance_to(anchor_position)
	if current_distance > rope_length:
		var direction = (anchor_position - player_position).normalized()

		var pull_force = direction * (current_distance - rope_length) * pull_factor * delta
		player.velocity += pull_force
