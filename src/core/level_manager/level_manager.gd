extends Node2D
class_name LevelManager

signal player_died

@export var camera_limit_left: float = 0
@export var camera_limit_right: float = 10000
@export var camera_limit_top: float = 0
@export var camera_limit_bottom: float = 2000

@export var level_name: String = ""
@export var next_level_path: String = ""

@export var player_start_point: Marker2D
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
	_player.player_death.connect(_on_player_death)
	
	_pathfinder_manager = get_node("Pathfinder")
	if _pathfinder_manager:
		_pathfinder_manager.set_player(_player)
		_pathfinder_manager.register_existing_characters()
	
	_place_player_at_start(true)
	
	await get_tree().create_timer(0.3).timeout
	_store_initial_level_state()
	call_deferred("_find_and_register_checkpoints")


func _process(_delta: float) -> void:
	if _player and _player.global_position.y > respawn_height:
		_on_player_death()
	
	if Input.is_action_just_pressed("ui_cancel"): # TODO just for test
		LeaderboardManager.set_skip_detection(true)
		_complete_level()


func _place_player_at_start(pvisible: bool = true) -> void:
	call_deferred("_apply_camera_limits")
	_player.velocity = Vector2.ZERO
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
			if node is HookPoint:
				data["x_scale"] = node.x_scale
				data["is_one_time_use"] = node.is_one_time_use
				data["one_time_use_chance"] = node.one_time_use_chance
				data["rotation"] = node.rotation
			if node is DestructiblePlatform:
				data["platform_length"] = node.platform_length
				data["destruction_time"] = node.destruction_time
			_original_nodes_data.append(data)


func _recreate_nodes() -> void:
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
	#tween.tween_interval(0.5)
	
	# 2 - Clear existing entities
	tween.tween_callback(func():
		if _pathfinder_manager:
			_pathfinder_manager.unregister_characters()
		
		var current_storable_nodes = get_tree().get_nodes_in_group("storable")
		current_storable_nodes += get_tree().get_nodes_in_group("debris")
		for node in current_storable_nodes:
			if is_instance_valid(node):
				node.queue_free()
		
		GameManager.update_loading_progress(0.6)
	)
	#tween.tween_interval(0.5)
	
	# 3 - Recreate entities
	tween.tween_callback(func():
		for data in _original_nodes_data:
			if data["scene_path"] and data["scene_path"] != "":
				var scene = load(data["scene_path"])
				if scene:
					var instance = scene.instantiate()
					
					if instance is HookPoint:
						instance.x_scale = data["x_scale"]
						instance.x_scale = data["x_scale"]
						instance.is_one_time_use = data["is_one_time_use"]
						instance.one_time_use_chance = data["one_time_use_chance"]
						instance.rotation = data["rotation"]
					
					elif instance is DestructiblePlatform:
						instance.platform_length = data["platform_length"]
						instance.destruction_time = data["destruction_time"]
						instance._original_position = data["position"]
						instance.global_position = data["position"]
					
					var parent = get_node_or_null(data["parent_path"])
					if parent:
						parent.add_child(instance)
					else:
						get_tree().current_scene.add_child(instance)
					instance.global_position = data["position"]
		
		GameManager.update_loading_progress(0.8)
	)
	#tween.tween_interval(0.5)
	
	# 4 - Final setup
	tween.tween_callback(func():
		_on_enemies_recreated()
		GameManager.update_loading_progress(1.0)
	)
	#tween.tween_interval(0.5)
	
	tween.tween_callback(func():
		GameManager.hide_loading_screen()
		_is_recreating_nodes = false
		emit_signal("player_died")
	)
	
	tween.play()


func _on_player_death() -> void:
	GameAnalytics.track_player_death(level_name, _player.global_position)
	_recreate_nodes()


func _on_enemies_recreated() -> void:
	if _pathfinder_manager:
		_pathfinder_manager.register_existing_characters()


func _find_and_register_checkpoints():
	await get_tree().process_frame
	
	_checkpoints = get_tree().get_nodes_in_group("checkpoints")
	#print("LevelManager: Found ", _checkpoints.size(), " checkpoints")
	
	for checkpoint in _checkpoints:
		checkpoint.checkpoint_activated.connect(_on_checkpoint_activated)
		_register_checkpoint(checkpoint)


func _register_checkpoint(checkpoint_node, data = {}):
	var checkpoint_id = checkpoint_node.get_path()
	_checkpoint_data[checkpoint_id] = data
	#print("LevelManager: Registered checkpoint at ", checkpoint_id)


func _on_checkpoint_activated(checkpoint) -> void:
	if _current_checkpoint:
		var cp = get_node_or_null(_current_checkpoint)
		if is_instance_valid(cp) and cp != checkpoint:
			cp.set_as_completed()
	
	_current_checkpoint = checkpoint.get_path()
	print("LevelManager: Activated checkpoint at ", _current_checkpoint)


func _complete_level() -> void:
	var level_time = GameManager.get_level_time()
	
	var completion_method = "skipped" if Input.is_action_just_pressed("ui_cancel") else "normal"
	if not LeaderboardManager.was_skipped():
		GameManager.save_level_time()
		GameAnalytics.track_level_completed(level_name, level_time)
	
	GameManager.remove_player_from_level()
	
	if next_level_path != "":
		GameManager.load_level(next_level_path)
	else:
		GameManager.complete_game()


func _on_level_exit() -> void:
	GameManager.remove_player_from_level()


func _apply_camera_limits() -> void:
	if _player and is_instance_valid(_player):
		var camera = _player.get_node_or_null("Camera2D")
		if camera:
			camera.limit_left = camera_limit_left
			camera.limit_right = camera_limit_right
			camera.limit_top = camera_limit_top
			camera.limit_bottom = camera_limit_bottom


func register_level_completed(area: Area2D) -> void:
	area.body_entered.connect(func(body):
		if body is Player:
			_complete_level()
	)
