extends CanvasLayer

@onready var debug_label = $DebugLabel

func _ready() -> void:
	if OS.is_debug_build():
		show()
	else:
		hide()


func _process(_delta: float) -> void:
	if not visible:
		return
	
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	
	var text = "Debug Info:\n"
	text += "-----------------------------------------------\n"
	
	text += "GameManager Info:\n"
	text += "- Current Level: " + GameManager.current_level + "\n"
	text += "- Total Game Time: " + str(snapped(GameManager._total_game_time, 0.01)) + "\n"
	text += "- Level Time: " + str(snapped(GameManager.get_level_time(), 0.01)) + "\n"
	text += "- Best Level Time: " + str(snapped(GameManager.get_best_time_for_level(GameManager.current_level), 0.01)) + "\n"
	text += "- Best Run Time: " + str(snapped(GameManager.get_best_run_time(), 0.01)) + "\n"
	text += "- Timer Paused: " + str(GameManager._timer_paused) + "\n"
	text += "- Is Loading: " + str(GameManager._is_loading) + "\n"
	text += "- Completed Levels: " + str(GameManager._completed_levels) + "\n"
	
	
	text += "\nLevelManager Info:\n"
	text += "- Level Name: " + level_manager.level_name + "\n"
	
	text += "- Current Checkpoint: " + str(level_manager._current_checkpoint) + "\n"
	text += "- Stored Nodes: " + str(level_manager._original_nodes_data.size()) + "\n"
	

	text += "\nScene Info:\n"
	var enemies_count = get_tree().get_nodes_in_group("Enemies").size()
	var checkpoints_count = get_tree().get_nodes_in_group("checkpoints").size()
	text += "- Enemies count: " + str(enemies_count) + "\n"
	text += "- Checkpoints count: " + str(checkpoints_count) + "\n"
	

	var player = get_tree().get_first_node_in_group("Player")
	if player:
		text += "\nPlayer Info:\n"
		text += "- Position: " + str(Vector2i(player.global_position)) + "\n"
	
	debug_label.text = text
