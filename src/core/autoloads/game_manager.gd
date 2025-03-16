extends Node

signal level_loaded
signal level_started
signal game_paused
signal game_resumed

# Global game state
var current_level: String = ""
var _next_level: String = ""
var _is_loading: bool = false
var _is_game_over: bool = false
var _is_paused: bool = false

# Global time tracking
var _total_game_time: float = 0.0
var _level_start_time: float = 0.0
var _timer_paused: bool = false
var _timer_paused_time: float = 0.0
var _best_times = {}

var _input_disabled: bool = false
var _input_process_mode_backup = null

var _pause_screen = null

var _player_instance = null
var _player_initialized: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize_player()
	_pause_screen = SceneManager.get_pause_screen_instance()
	get_tree().root.call_deferred("add_child", _pause_screen)
	load_best_times()


func _process(delta: float) -> void:
	if !_timer_paused and !_is_loading and current_level != "":
		_total_game_time += delta


func _input(event) -> void:
	if event.is_action_pressed("pause"):
		if !_is_loading and !_input_disabled:
			_toggle_pause()


func load_level(level_path: String) -> void:
	print("GameManager: Loading level: ", level_path)
	_next_level = level_path
	
	_is_loading = true
	
	if not SceneChanger.is_connected("scene_loaded", Callable(self, "_on_scene_loaded")):
		SceneChanger.connect("scene_loaded", Callable(self, "_on_scene_loaded"))
	
	SceneChanger.goto_scene(level_path)


func _on_scene_loaded() -> void:
	current_level = _next_level
	_level_start_time = _total_game_time
	
	_is_loading = false
	
	emit_signal("level_loaded")
	emit_signal("level_started")


func show_loading_screen() -> void:
	disable_player_input()
	_pause_timer()
	LoadingScreen.show_loading_screen()


func hide_loading_screen() -> void:
	LoadingScreen.hide_loading_screen()
	_resume_timer()
	enable_player_input()


func update_loading_progress(progress: float) -> void:
	LoadingScreen.update_progress(progress)


func _pause_timer() -> void:
	if !_timer_paused:
		_timer_paused = true
		_timer_paused_time = Time.get_ticks_msec() / 1000.0


func _resume_timer() -> void:
	if _timer_paused:
		_timer_paused = false


func get_level_time() -> float:
	if current_level == "":
		return 0.0
	return _total_game_time - _level_start_time


func save_best_time() -> bool:
	var level_time = get_level_time()
	if !_best_times.has(current_level) or level_time < _best_times[current_level]:
		_best_times[current_level] = level_time
		_save_best_times()
		return true
	return false


func _save_best_times() -> void:
	var save_file = FileAccess.open("user://best_times.save", FileAccess.WRITE)
	save_file.store_var(_best_times)
	save_file.close()


func load_best_times() -> void:
	if FileAccess.file_exists("user://best_times.save"):
		var save_file = FileAccess.open("user://best_times.save", FileAccess.READ)
		_best_times = save_file.get_var()
		save_file.close()


func _pause_game() -> void:
	if !_is_paused:
		_pause_timer()
		_is_paused = true
		get_tree().paused = true
		_show_pause_menu()
		emit_signal("game_paused")


func resume_game() -> void:
	if _is_paused:
		_is_paused = false
		get_tree().paused = false
		_hide_pause_menu()
		emit_signal("game_resumed")
		_resume_timer()


func _toggle_pause() -> void:
	resume_game() if _is_paused else _pause_game()


func _show_pause_menu() -> void:
	_pause_screen.show_pause_screen()


func _hide_pause_menu(animation: bool = true) -> void:
	_pause_screen.hide_pause_screen(animation)


func restart_game() -> void:
	_hide_pause_menu(false)	
	if _is_paused:
		_is_paused = false
		get_tree().paused = false
	
	current_level = ""
	_total_game_time = 0.0
	
	load_level(SceneManager.BaseGameLevel)
	_resume_timer()


func disable_player_input() -> void:
	_player_instance.visible = false
	if _input_disabled:
		return
		
	_input_disabled = true
	
	if _player_instance and is_instance_valid(_player_instance):
		call_deferred("_apply_player_input_state", false)


func enable_player_input() -> void:
	if !_input_disabled:
		return
		
	_input_disabled = false
	
	if _player_instance and is_instance_valid(_player_instance):
		call_deferred("_apply_player_input_state", true)
	_player_instance.visible = true


func _apply_player_input_state(enabled: bool) -> void:
	_player_instance.set_process_input(enabled)
	_player_instance.set_physics_process(enabled)


func initialize_player() -> void:
	if _player_initialized:
		return
	
	_player_instance = SceneManager.get_player_instance()
	_player_instance.visible = false
	get_tree().root.call_deferred("add_child", _player_instance)
	_player_initialized = true


func get_player() -> Player:
	return _player_instance


func place_player_in_level(position: Vector2, pvisible: bool = true) -> void:
	_player_instance.global_position = position
	_player_instance.visible = pvisible


func remove_player_from_level() -> void:
	_player_instance.visible = false
	_player_instance.global_position = Vector2(-2000, 0)


func reset_best_times() -> void:
	_best_times = {}
	
	if FileAccess.file_exists("user://best_times.save"):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("user://best_times.save")
