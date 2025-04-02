extends CanvasLayer

@onready var main_container = $Control/CenterContainer
@onready var settings_container = $Control/SettingsContainer
@onready var stats_container = $Control/StatsContainer
@onready var leaderboard_container = $Control/TaloLeaderboardContainer
@onready var control = $Control

@onready var new_game_button = $Control/CenterContainer/VBoxContainer/NewGameButton
@onready var settings_button = $Control/CenterContainer/VBoxContainer/SettingsButton
@onready var stats_button = $Control/CenterContainer/VBoxContainer/StatsButton
@onready var leaderboard_button = $Control/CenterContainer/VBoxContainer/LeaderboardButton
@onready var quit_button = $Control/CenterContainer/VBoxContainer/QuitButton

var _in_start_screen_context: bool = true

var _buttons: Array = []
var _current_button_index: int = 0
var _in_main_menu: bool = false


func _ready() -> void:
	add_to_group("ui_screen")
	
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	_buttons = [new_game_button, settings_button, stats_button, leaderboard_button, quit_button]
	
	show_main_menu()
	
	settings_container.settings_closed.connect(_on_settings_closed)
	
	settings_container.visible = false
	stats_container.visible = false
	leaderboard_container.visible = false
	
	stats_container.back_pressed.connect(_on_back_from_stats_pressed)
	leaderboard_container.back_pressed.connect(_on_back_from_leaderboard_pressed)


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
	
	leaderboard_container.visible = false
	stats_container.visible = false
	settings_container.visible = false
	
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
	hide_stats()
	hide_leaderboard()
	settings_container.visible = true
	
	settings_container.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(settings_container, "modulate:a", 1.0, 0.2)


func _on_settings_closed() -> void:
	if _in_start_screen_context:
		await get_tree().create_timer(0.1).timeout
		show_main_menu()


func show_stats() -> void:
	_in_main_menu = false
	GameManager.load_times()
	
	hide_main_menu()
	stats_container.visible = true
	stats_container.update_stats()
	
	var tween = create_tween()
	tween.tween_property(stats_container, "position", Vector2.ZERO, 0.3).from(Vector2(-get_viewport().get_visible_rect().size.x, 0))


func show_leaderboard() -> void:
	_in_main_menu = false
	GameManager.load_times()
	
	hide_main_menu()
	
	leaderboard_container.position = Vector2(-get_viewport().get_visible_rect().size.x, 0)
	leaderboard_container.visible = true
	leaderboard_container.initialize()
	
	var tween = create_tween()
	tween.tween_property(leaderboard_container, "position", Vector2.ZERO, 0.3)


func hide_stats() -> void:
	var tween = create_tween()
	tween.tween_property(stats_container, "position", Vector2(-get_viewport().get_visible_rect().size.x, 0), 0.3)
	tween.tween_callback(func(): stats_container.visible = false)


func hide_leaderboard() -> void:
	var tween = create_tween()
	tween.tween_property(leaderboard_container, "position", Vector2(-get_viewport().get_visible_rect().size.x, 0), 0.3)
	tween.tween_callback(func(): leaderboard_container.visible = false)


func hide_all_screens() -> void:
	_in_main_menu = false
	main_container.visible = false
	settings_container.visible = false
	stats_container.visible = false
	leaderboard_container.visible = false
	control.visible = false
	
	_in_start_screen_context = false


func _on_new_game_pressed() -> void:
	hide_all_screens()
	
	GameManager.prepare_for_new_game()
	GameManager.load_level(SceneManager.Level01Path)


func _on_settings_pressed() -> void:
	show_settings()


func _on_stats_pressed() -> void:
	show_stats()


func _on_leaderboard_pressed() -> void:
	show_leaderboard()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_from_stats_pressed() -> void:
	hide_stats()
	show_main_menu()


func _on_back_from_leaderboard_pressed() -> void:
	hide_leaderboard()
	show_main_menu()
