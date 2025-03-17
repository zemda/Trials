extends Node2D
class_name LevelManager

signal player_died

@export var level_name: String = ""
@export var next_level_path: String = ""

@export var player_start_point: Node2D
@export var respawn_height: float = 2000

var _player: Player
var _checkpoints: Array = []
var _pathfinder_manager = null

var _current_checkpoint = null
var _checkpoint_data: Dictionary = {}

var _original_nodes_data: Array = [] # stores enemies, TODO will store also one time grappling points, destroyable platforms, ...

var _is_recreating_nodes: bool = false


func _ready() -> void:
	add_to_group("level_manager")
	
	GameManager.current_level = get_tree().current_scene.scene_file_path
	print("LevelManager: Initialized ", get_tree().current_scene.scene_file_path)
	
	_player = GameManager.get_player()
	_player.connect("player_death", Callable(self, "_on_player_death"))
	
	_pathfinder_manager = get_parent().get_node_or_null("Pathfinder")
	if _pathfinder_manager:
		_pathfinder_manager.set_player(_player)
	
	call_deferred("_find_and_register_checkpoints")
	_place_player_at_start(true)
	
	await get_tree().create_timer(0.3).timeout
	_store_initial_level_state()


func _process(delta: float) -> void:
	if _player and _player.global_position.y > respawn_height:
		_on_player_death()
	
	if Input.is_action_just_pressed("ui_cancel"): # TODO just for test
		_complete_level()


func _place_player_at_start(pvisible: bool = true) -> void:
	if _current_checkpoint == null:
		GameManager.place_player_in_level(player_start_point.global_position, pvisible)
	else:
		var checkpoint_node = get_node_or_null(_current_checkpoint)
		if is_instance_valid(checkpoint_node):
			GameManager.place_player_in_level(checkpoint_node.global_position, pvisible)
		else:
			GameManager.place_player_in_level(player_start_point.global_position, pvisible)


func _store_initial_level_state() -> void:
	_original_nodes_data = []
	var nodes = get_tree().get_nodes_in_group("storable")	
	for node in nodes:
		if is_instance_valid(node) and node.scene_file_path != "":
			var data = {
				"scene_path": node.scene_file_path,
				"position": node.global_position,
				"parent_path": node.get_parent().get_path()
			}
			_original_nodes_data.append(data)


func _recreate_nodes() -> void: # TODO remove fake loading time
	print("LevelManager: Respawning player & nodes")
	
	if _is_recreating_nodes:
		return
	_is_recreating_nodes = true
	
	GameManager.show_loading_screen()
	
	var tween = create_tween()
	
	# 1 - Reset player position
	tween.tween_callback(func():
		_place_player_at_start(false)
		GameManager.update_loading_progress(0.3)
	)
	tween.tween_interval(0.5)
	
	# 2 - Clear existing entities
	tween.tween_callback(func():
		if _pathfinder_manager:
			_pathfinder_manager.unregister_characters()
		
		var current_storable_nodes = get_tree().get_nodes_in_group("storable")		
		for node in current_storable_nodes:
			if is_instance_valid(node):
				node.queue_free()
		
		GameManager.update_loading_progress(0.6)
	)
	tween.tween_interval(0.5)
	
	# 3 - Recreate entities
	tween.tween_callback(func():
		for data in _original_nodes_data:
			if data["scene_path"] and data["scene_path"] != "":
				var scene = load(data["scene_path"])
				if scene:
					var instance = scene.instantiate()
					var parent = get_node_or_null(data["parent_path"])
					if parent:
						parent.add_child(instance)
					else:
						get_tree().current_scene.add_child(instance)
					instance.global_position = data["position"]
		
		GameManager.update_loading_progress(0.8)
	)
	tween.tween_interval(0.5)
	
	# 4 - Final setup
	tween.tween_callback(func():
		_on_enemies_recreated()
		GameManager.update_loading_progress(1.0)
	)
	tween.tween_interval(0.5)
	
	tween.tween_callback(func():
		GameManager.hide_loading_screen()
		_is_recreating_nodes = false
		emit_signal("player_died")
	)
	
	tween.play()


func _on_player_death() -> void:
	_recreate_nodes()


func _on_enemies_recreated() -> void:
	if _pathfinder_manager:
		_pathfinder_manager.register_existing_characters()


func _find_and_register_checkpoints():
	await get_tree().process_frame
	
	_checkpoints = get_tree().get_nodes_in_group("checkpoints") # TODO might register cp from previous level
	print("LevelManager: Found ", _checkpoints.size(), " checkpoints")
	
	for checkpoint in _checkpoints:
		checkpoint.connect("checkpoint_activated", Callable(self, "_on_checkpoint_activated"))
		_register_checkpoint(checkpoint)


func _register_checkpoint(checkpoint_node, data = {}):
	var checkpoint_id = checkpoint_node.get_path()
	_checkpoint_data[checkpoint_id] = data
	print("LevelManager: Registered checkpoint at ", checkpoint_id)


func _on_checkpoint_activated(checkpoint) -> void:
	if _current_checkpoint:
		var cp = get_node_or_null(_current_checkpoint)
		if is_instance_valid(cp) and cp != checkpoint:
			cp.set_as_completed()
	
	_current_checkpoint = checkpoint.get_path()
	print("LevelManager: Activated checkpoint at ", _current_checkpoint)


func _complete_level() -> void:
	GameManager.disable_player_input()
	GameManager.save_best_time()
	GameManager.remove_player_from_level()
	
	if next_level_path != "":
		GameManager.load_level(next_level_path)
	else:
		GameManager.complete_game()
		GameManager.enable_player_input()


func _on_level_exit() -> void:
	GameManager.remove_player_from_level()
