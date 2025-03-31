extends Node

signal level_loaded
signal level_started
signal game_paused
signal game_resumed
signal run_completed


const _config_path: String = "user://game_times.cfg"
var _config: ConfigFile = ConfigFile.new()
const _veri_secret: String = "VeLiCeTaJne h3sl0, n1k0mu h0 nerik3jte pls..."

var current_level: String = ""
var _next_level: String = ""
var _is_loading: bool = false
var _is_paused: bool = false

var _total_game_time: float = 0.0
var _level_start_time: float = 0.0
var _timer_paused: bool = false
var _timer: Timer
var _completed_levels: Array[String] = []

var _input_disabled: bool = false

var _pause_screen = null

var _player_instance = null
var _player_initialized: bool = false


func _ready() -> void:
	load_times()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_screen = SceneManager.get_pause_screen_instance()
	get_tree().root.call_deferred("add_child", _pause_screen)
	
	_timer = Timer.new()
	_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_timer.wait_time = 0.01
	_timer.autostart = true
	_timer.timeout.connect(_on_timer_tick)
	add_child(_timer)
	
	SceneChanger.scene_loaded.connect(_on_scene_loaded)


func _on_timer_tick() -> void:
	if !_timer_paused and !_is_loading and current_level != "" and is_in_gameplay_level():
		_total_game_time += _timer.wait_time


func _input(event) -> void:
	if event.is_action_pressed("pause"): # TODO add also esc later
		if !_is_loading and !_input_disabled and is_in_gameplay_level():
			_toggle_pause()


func load_level(level_path: String) -> void:
	print("GameManager: Loading level: ", level_path)
	_next_level = level_path
	_is_loading = true
	
	SceneChanger.goto_scene(level_path)


func _on_scene_loaded() -> void:
	_is_loading = false
	if not is_in_gameplay_level():
		return

	load_times()
	current_level = _next_level
	_level_start_time = _total_game_time
	enable_player_input()
	_player_instance.visible = true
	_resume_timer()
	
	if not _completed_levels.has(current_level):
		_completed_levels.append(current_level)
	
	emit_signal("level_loaded")
	emit_signal("level_started")


func is_in_gameplay_level() -> bool:
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene.is_in_group("gameplay_level")
	return false


func is_in_ui_screen() -> bool:
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene.is_in_group("ui_screen")
	return false


func show_loading_screen() -> void:
	disable_player_input()
	_pause_timer()
	LoadingScreen.show_loading_screen()


func hide_loading_screen() -> void:
	LoadingScreen.hide_loading_screen()
	_resume_timer()
	if is_in_gameplay_level():
		enable_player_input()


func update_loading_progress(progress: float) -> void:
	LoadingScreen.update_progress(progress)


func _pause_timer() -> void:
	if !_timer_paused:
		_timer_paused = true
		_timer.paused = true


func _resume_timer() -> void:
	if _timer_paused:
		_timer_paused = false
		_timer.paused = false


func get_level_time() -> float:
	if current_level == "" or !is_in_gameplay_level():
		return 0.0
	return _total_game_time - _level_start_time


func save_best_time() -> bool:
	var level_time = get_level_time()
	var best_time = get_best_time_for_level(current_level)
	
	if best_time == 0.0 or level_time < best_time:
		_config.set_value("level_times", current_level, level_time)
		save_times()
		return true
	return false


func get_best_time_for_level(level: String) -> float:
	if level == "":
		return 0.0
	return _config.get_value("level_times", level, 0.0)


func get_current_run_time() -> float:
	if !is_in_gameplay_level():
		return 0.0
	return _total_game_time


func get_best_run_time() -> float:
	return _config.get_value("run_times", "best_time", 0.0)


func save_run_time() -> bool:
	var run_time = _total_game_time
	var best_run_time = get_best_run_time()
	
	if best_run_time == 0.0 or run_time < best_run_time:
		_config.set_value("run_times", "best_time", run_time)
		save_times()
		emit_signal("run_completed", run_time)
		return true
	return false


func save_times() -> void:
	var error = _config.save_encrypted_pass(_config_path, _veri_secret)
	if error != OK:
		print("GameManager: Error saving times: ", error)


func load_times() -> void:
	if FileAccess.file_exists(_config_path):
		var error = _config.load_encrypted_pass(_config_path, _veri_secret)
		if error != OK:
			print("GameManager: Error loading times: ", error)
	else:
		_config.set_value("level_times", "initialized", true)
		_config.set_value("run_times", "initialized", true)
		save_times()


func complete_game() -> void: # TODO end screen or smh
	_pause_timer()
	save_run_time()
	SceneChanger.goto_scene(SceneManager.EndScreenPath)


func _pause_game() -> void:
	if !_is_paused and is_in_gameplay_level():
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
	_delete_player()
	current_level = ""
	_total_game_time = 0.0
	_completed_levels.clear()
	
	load_level(SceneManager.Level01Path)


func _delete_player() -> void:
	_player_instance.queue_free()
	_player_initialized = false


func prepare_for_new_game() -> void:
	current_level = ""
	_total_game_time = 0.0
	_completed_levels.clear()
	
	if not _player_initialized:
		initialize_player()
	
	_player_instance.global_position = Vector2(-2000, 0)
	_player_instance.visible = false



func disable_player_input() -> void:
	if _input_disabled or !_player_initialized:
		return
	_player_instance.velocity = Vector2.ZERO
	call_deferred("_deferred_player_input_helper", false)
	_player_instance.visible = false
	_input_disabled = true


func go_to_main_menu() -> void:
	if _is_paused:
		_is_paused = false
		get_tree().paused = false
	_delete_player()
	SceneChanger.goto_scene(SceneManager.StartScreenPath)


func _deferred_player_input_helper(enable: bool) -> void:
	if enable:
		_player_instance.process_mode = Node.PROCESS_MODE_INHERIT
		_player_instance.set_physics_process(true)
		_player_instance.set_process(true)
		_player_instance.set_process_input(true)
	else:
		_player_instance.process_mode = Node.PROCESS_MODE_DISABLED
		_player_instance.set_physics_process(false)
		_player_instance.set_process(false)
		_player_instance.set_process_input(false)


func enable_player_input() -> void:
	if !_input_disabled or !_player_initialized:
		return
	call_deferred("_deferred_player_input_helper", true)
	
	_player_instance.visible = true
	_input_disabled = false


func initialize_player() -> void:
	_player_instance = SceneManager.get_player_instance()
	_player_instance.visible = false
	get_tree().root.call_deferred("add_child", _player_instance)
	
	_player_instance.global_position = Vector2(-2000, 0)
	
	_player_instance.set_physics_process(false)
	_player_instance.set_process_input(false)
	
	_player_initialized = true


func get_player() -> Player:
	if not _player_initialized:
		initialize_player()
	return _player_instance


func place_player_in_level(position: Vector2, pvisible: bool = true) -> void:
	_player_instance.global_position = position
	_player_instance.visible = pvisible and is_in_gameplay_level()
	
	if is_in_gameplay_level() and !_input_disabled:
		_player_instance.set_physics_process(true)
		_player_instance.set_process_input(true)
	_player_instance.velocity = Vector2.ZERO


func remove_player_from_level() -> void:
	_player_instance.visible = false
	_player_instance.global_position = Vector2(-2000, 0)
	_player_instance.set_physics_process(false)
	_player_instance.set_process_input(false)


func reset_best_times() -> void:
	_config = ConfigFile.new()
	if FileAccess.file_exists(_config_path):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(_config_path)
