extends CanvasLayer

@export_file("*.tscn") var first_level_path: String = ""

@onready var main_container = $Control/CenterContainer
@onready var settings_container = $Control/SettingsContainer
@onready var leaderboard_container = $Control/LeaderboardContainer
@onready var levels_grid = $Control/LeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/LevelsGrid
@onready var best_run_label = $Control/LeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/BestRunLabel
@onready var control = $Control

@onready var new_game_button = $Control/CenterContainer/VBoxContainer/NewGameButton
@onready var settings_button = $Control/CenterContainer/VBoxContainer/SettingsButton
@onready var leaderboard_button = $Control/CenterContainer/VBoxContainer/LeaderboardButton
@onready var quit_button = $Control/CenterContainer/VBoxContainer/QuitButton

var _title_tween: Tween
var _in_start_screen_context: bool = true

var _buttons: Array = []
var _current_button_index: int = 0
var _in_main_menu: bool = false


func _ready() -> void:
	add_to_group("ui_screen")
	
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	$Control/LeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_back_from_leaderboard_pressed)
	
	_buttons = [new_game_button, settings_button, leaderboard_button, quit_button]
	
	show_main_menu()
	
	settings_container.connect("settings_closed", _on_settings_closed)
	
	settings_container.visible = false
	leaderboard_container.visible = false
	
	if first_level_path.is_empty():
		first_level_path = SceneManager.BaseGameLevel
	
	_update_leaderboard()


func _input(event: InputEvent) -> void:
	if _in_main_menu:
		if event.is_action_pressed("ui_up"):
			_navigate_up()
		if event.is_action_pressed("ui_down"):
			_navigate_down()
		if event.is_action_pressed("ui_accept"):
			_press_current_button()


func _navigate_up() -> void:
	_current_button_index = (_current_button_index - 1) % _buttons.size()
	if _current_button_index < 0:
		_current_button_index = _buttons.size() - 1
	_update_button_focus()


func _navigate_down() -> void:
	_current_button_index = (_current_button_index + 1) % _buttons.size()
	_update_button_focus()


func _press_current_button() -> void:
	if _current_button_index >= 0 and _current_button_index < _buttons.size():
		_buttons[_current_button_index].emit_signal("pressed")


func _update_button_focus() -> void:
	for button in _buttons:
		button.focus_mode = Control.FOCUS_NONE
		button.flat = false
	
	_buttons[_current_button_index].focus_mode = Control.FOCUS_ALL
	_buttons[_current_button_index].grab_focus()
	_buttons[_current_button_index].flat = true


func show_main_menu() -> void:
	main_container.visible = true
	_in_main_menu = true
	
	var tween = create_tween()
	tween.tween_property(main_container, "modulate", Color(1, 1, 1, 1), 0.3).from(Color(1, 1, 1, 0))
	
	_current_button_index = 0
	_update_button_focus()


func hide_main_menu() -> void:
	_in_main_menu = false
	
	var tween = create_tween()
	tween.tween_property(main_container, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): main_container.visible = false)


func show_settings() -> void:
	_in_start_screen_context = true
	_in_main_menu = false
	
	hide_main_menu()
	hide_leaderboard()
	settings_container.visible = true
	
	settings_container.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(settings_container, "modulate:a", 1.0, 0.2)


func _on_settings_closed() -> void:
	if _in_start_screen_context:
		await get_tree().create_timer(0.1).timeout
		show_main_menu()


func show_leaderboard() -> void:
	_in_main_menu = false
	
	hide_main_menu()
	leaderboard_container.visible = true
	
	var tween = create_tween()
	tween.tween_property(leaderboard_container, "position", Vector2.ZERO, 0.3).from(Vector2(-get_viewport().get_visible_rect().size.x, 0))


func hide_leaderboard() -> void:
	var tween = create_tween()
	tween.tween_property(leaderboard_container, "position", Vector2(-get_viewport().get_visible_rect().size.x, 0), 0.3)
	tween.tween_callback(func(): leaderboard_container.visible = false)


func hide_all_screens() -> void:
	_in_main_menu = false
	main_container.visible = false
	settings_container.visible = false
	leaderboard_container.visible = false
	control.visible = false
	
	_in_start_screen_context = false


func _update_leaderboard() -> void:
	for i in range(levels_grid.get_child_count() - 1, 1, -1):
		levels_grid.get_child(i).queue_free()
	
	best_run_label.text = "Best Run Time: " + format_time(GameManager.get_best_run_time())
	
	if GameManager._config.has_section("level_times"):
		for key in GameManager._config.get_section_keys("level_times"):
			if key != "initialized":
				var level_name = key.get_file().get_basename()
				if level_name.is_empty():
					var path = key
					var file = path.get_file()
					level_name = file.get_basename()
				
				var best_time = GameManager.get_best_time_for_level(key)
				_add_leaderboard_entry(level_name, best_time)


func _add_leaderboard_entry(level_name: String, time: float) -> void:
	var name_label = Label.new()
	name_label.text = level_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var time_label = Label.new()
	time_label.text = format_time(time)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	levels_grid.add_child(name_label)
	levels_grid.add_child(time_label)


func format_time(time_seconds: float) -> String:
	if time_seconds <= 0:
		return "--:--:--"
		
	var minutes = floor(time_seconds / 60)
	var seconds = fmod(time_seconds, 60)
	var milliseconds = fmod(time_seconds * 100, 100)
	
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


func _on_new_game_pressed() -> void:
	if first_level_path.is_empty():
		push_error("First level path is not set!")
		return
	
	hide_all_screens()
	
	GameManager.prepare_for_new_game()
	SceneChanger.goto_scene(first_level_path)


func _on_settings_pressed() -> void:
	show_settings()


func _on_leaderboard_pressed() -> void:
	show_leaderboard()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_from_leaderboard_pressed() -> void:
	hide_leaderboard()
	show_main_menu()
