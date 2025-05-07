extends EnemyMove



func update(delta: float) -> void:
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
	else:
		host.velocity.x = 0
	_path_recalculation_timer += delta


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enemy_shoot_test"):
		var pl =  get_tree().get_first_node_in_group("Player")
		var global_click_pos = pl.get_global_mouse_position()
		
		print("Global position: ", global_click_pos)
		move_to(global_click_pos)
	


func _transition() -> int:
	return states.NONE
