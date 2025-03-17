extends CanvasLayer

@export_file("*.tscn") var first_level_path: String = ""

@onready var main_container = $Control/CenterContainer
@onready var settings_container = $Control/SettingsContainer
@onready var leaderboard_container = $Control/LeaderboardContainer
@onready var levels_grid = $Control/LeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/LevelsGrid
@onready var best_run_label = $Control/LeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/BestRunLabel
@onready var title_label = $Control/CenterContainer/VBoxContainer/TitleLabel
@onready var control = $Control

var _title_tween: Tween
var _in_start_screen_context: bool = true


func _ready() -> void:
	add_to_group("ui_screen")
	
	$Control/CenterContainer/VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$Control/CenterContainer/VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$Control/CenterContainer/VBoxContainer/LeaderboardButton.pressed.connect(_on_leaderboard_pressed)
	$Control/CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$Control/LeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_back_from_leaderboard_pressed)
	
	show_main_menu()
	_animate_title()
	
	settings_container.connect("settings_closed", _on_settings_closed)
	
	settings_container.visible = false
	leaderboard_container.visible = false
	
	if first_level_path.is_empty():
		first_level_path = SceneManager.BaseGameLevel
	
	_update_leaderboard()


func _animate_title() -> void:
	if _title_tween and _title_tween.is_valid():
		_title_tween.kill()
	
	_title_tween = create_tween()
	_title_tween.set_loops()
	_title_tween.tween_property(title_label, "modulate", Color(1, 1, 1, 0.8), 1.5)
	_title_tween.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 1.5)


func show_main_menu() -> void:
	main_container.visible = true
	
	var tween = create_tween()
	tween.tween_property(main_container, "modulate", Color(1, 1, 1, 1), 0.3).from(Color(1, 1, 1, 0))


func hide_main_menu() -> void:
	var tween = create_tween()
	tween.tween_property(main_container, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): main_container.visible = false)


func show_settings() -> void:
	_in_start_screen_context = true
	
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
	hide_main_menu()
	leaderboard_container.visible = true
	
	var tween = create_tween()
	tween.tween_property(leaderboard_container, "position", Vector2.ZERO, 0.3).from(Vector2(-get_viewport().get_visible_rect().size.x, 0))


func hide_leaderboard() -> void:
	var tween = create_tween()
	tween.tween_property(leaderboard_container, "position", Vector2(-get_viewport().get_visible_rect().size.x, 0), 0.3)
	tween.tween_callback(func(): leaderboard_container.visible = false)


func hide_all_screens() -> void:
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
