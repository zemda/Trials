extends RigidBody2D

signal player_entered_segment
signal player_exited_segment


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("player_entered_segment", body)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("player_exited_segment", body)
