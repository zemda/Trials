extends CanvasLayer

@onready var main_container = $Control/CenterContainer
@onready var settings_container = $Control/SettingsContainer
@onready var stats_container = $Control/StatsContainer
@onready var levels_grid = $Control/StatsContainer/PanelContainer/MarginContainer/VBoxContainer/LevelsGrid
@onready var best_run_label = $Control/StatsContainer/PanelContainer/MarginContainer/VBoxContainer/BestRunLabel
@onready var control = $Control

@onready var new_game_button = $Control/CenterContainer/VBoxContainer/NewGameButton
@onready var settings_button = $Control/CenterContainer/VBoxContainer/SettingsButton
@onready var stats_button = $Control/CenterContainer/VBoxContainer/StatsButton
@onready var leaderboard_button = $Control/CenterContainer/VBoxContainer/LeaderboardButton
@onready var quit_button = $Control/CenterContainer/VBoxContainer/QuitButton

@onready var leaderboard_container = $Control/TaloLeaderboardContainer
@onready var level_select_option = $Control/TaloLeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/LevelSelectContainer/LevelSelectOption
@onready var leaderboard_entries_container = $Control/TaloLeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/EntriesContainer
@onready var refresh_button = $Control/TaloLeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/LevelSelectContainer/RefreshButton
@onready var loading_label = $Control/TaloLeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/LoadingLabel
@onready var back_button = $Control/TaloLeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton

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
	
	$Control/StatsContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_back_from_stats_pressed)
	
	back_button.pressed.connect(_on_back_from_leaderboard_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	level_select_option.item_selected.connect(_on_level_selected)
	
	_buttons = [new_game_button, settings_button, stats_button, leaderboard_button, quit_button]
	
	show_main_menu()
	
	settings_container.settings_closed.connect(_on_settings_closed)
	
	settings_container.visible = false
	stats_container.visible = false
	leaderboard_container.visible = false
	
	_populate_level_select()
	_configure_leaderboard_layout()


func _configure_leaderboard_layout() -> void:
	var vbox = $Control/TaloLeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer
	
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	vbox.add_theme_constant_override("separation", 8)
	
	var scroll = $Control/TaloLeaderboardContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	scroll.custom_minimum_size = Vector2(0, 150)
	
	leaderboard_entries_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	back_button.size_flags_vertical = Control.SIZE_SHRINK_END
	back_button.custom_minimum_size = Vector2(0, 40)
	back_button.focus_mode = Control.FOCUS_ALL
	
	back_button.add_theme_color_override("font_color", Color(1, 1, 1))
	back_button.add_theme_color_override("font_hover_color", Color(0.8, 0.8, 1))
	
	var panel = $Control/TaloLeaderboardContainer/PanelContainer
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var margin = $Control/TaloLeaderboardContainer/PanelContainer/MarginContainer
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.custom_minimum_size = Vector2(0, 20)
	
	leaderboard_container.size = get_viewport().get_visible_rect().size


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
	_update_stats()
	
	hide_main_menu()
	stats_container.visible = true
	
	var tween = create_tween()
	tween.tween_property(stats_container, "position", Vector2.ZERO, 0.3).from(Vector2(-get_viewport().get_visible_rect().size.x, 0))


func show_leaderboard() -> void:
	_in_main_menu = false
	GameManager.load_times()
	
	hide_main_menu()
	
	leaderboard_container.position = Vector2(-get_viewport().get_visible_rect().size.x, 0)
	leaderboard_container.visible = true
	
	for child in leaderboard_entries_container.get_children():
		child.queue_free()
	
	call_deferred("_configure_leaderboard_layout")
	
	var tween = create_tween()
	tween.tween_property(leaderboard_container, "position", Vector2.ZERO, 0.3)
	
	_refresh_leaderboard()


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


func _update_stats() -> void:
	for i in range(levels_grid.get_child_count()):
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
				_add_stats_entry(level_name, best_time)


func _add_stats_entry(level_name: String, time: float) -> void:
	var name_label = Label.new()
	name_label.text = level_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var time_label = Label.new()
	time_label.text = format_time(time)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	levels_grid.add_child(name_label)
	levels_grid.add_child(time_label)


func _populate_level_select() -> void:
	level_select_option.clear()
	
	level_select_option.add_item("Game Completion Times", 0)
	
	var level_index = 1
	if GameManager._config.has_section("level_times"):
		for key in GameManager._config.get_section_keys("level_times"):
			if key != "initialized":
				var level_name = key.get_file().get_basename()
				if level_name.is_empty():
					var path = key
					var file = path.get_file()
					level_name = file.get_basename()
				
				level_select_option.add_item(level_name, level_index)
				level_index += 1


func _refresh_leaderboard() -> void:
	loading_label.visible = true
	
	for child in leaderboard_entries_container.get_children():
		child.queue_free()
	
	var selected_id = level_select_option.get_selected_id()
	var leaderboard_name = ""
	
	if selected_id == 0:
		leaderboard_name = LeaderboardManager.GAME_COMPLETION_LEADERBOARD
	else:
		var level_name = level_select_option.get_item_text(selected_id)
		leaderboard_name = LeaderboardManager.LEVEL_TIME_LEADERBOARD_PREFIX + level_name
	
	call_deferred("_fetch_leaderboard_entries", leaderboard_name)


func _on_refresh_pressed() -> void:
	_refresh_leaderboard()


func _on_level_selected(index: int) -> void:
	_refresh_leaderboard()


func _fetch_leaderboard_entries(leaderboard_name: String) -> void:
	var entries = []
	
	if Talo.identity_check() == OK:
		var res = await Talo.leaderboards.get_entries(leaderboard_name, 0)
		entries = res.entries
		
		var player_res = await Talo.leaderboards.get_entries_for_current_player(leaderboard_name, 0)
		var player_position = -1
		var player_score = 0.0
		
		if player_res.entries.size() > 0:
			player_position = player_res.entries[0].position
			player_score = player_res.entries[0].score
		
		_populate_leaderboard_entries(entries, player_position, player_score)
	else:
		_add_leaderboard_message("Player not authenticated. Please restart the game.")
	
	loading_label.visible = false


func _populate_leaderboard_entries(entries: Array, player_position: int, player_score: float) -> void:
	if entries.size() == 0:
		_add_leaderboard_message("No entries found. Be the first to complete!")
		return
	
	var selected_id = level_select_option.get_selected_id()
	var level_name = level_select_option.get_item_text(selected_id)
	
	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var rank_header = Label.new()
	rank_header.text = "Rank"
	rank_header.custom_minimum_size = Vector2(50, 0)
	
	var player_header = Label.new()
	player_header.text = "Player"
	player_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var time_header = Label.new()
	time_header.text = "Time"
	time_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_header.custom_minimum_size = Vector2(100, 0)
	
	header.add_child(rank_header)
	header.add_child(player_header)
	header.add_child(time_header)
	
	leaderboard_entries_container.add_child(header)
	
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(0, 4)
	leaderboard_entries_container.add_child(separator)
	
	var current_player_id = ""
	if Talo.current_alias != null:
		current_player_id = Talo.current_alias.identifier
	
	for i in range(min(10, entries.size())):
		var entry = entries[i]
		
		var entry_container = HBoxContainer.new()
		entry_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_container.custom_minimum_size = Vector2(0, 20)
		
		var rank_label = Label.new()
		rank_label.text = "#" + str(entry.position + 1)
		rank_label.custom_minimum_size = Vector2(50, 0)
		
		var player_label = Label.new()
		player_label.text = entry.player_alias.identifier
		player_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var time_label = Label.new()
		time_label.text = format_time(entry.score)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		time_label.custom_minimum_size = Vector2(100, 0)
		
		if current_player_id != "" and entry.player_alias.identifier == current_player_id:
			rank_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
			player_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
			time_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
		
		entry_container.add_child(rank_label)
		entry_container.add_child(player_label)
		entry_container.add_child(time_label)
		
		leaderboard_entries_container.add_child(entry_container)
	
	if player_position >= 10 and player_position >= 0 and current_player_id != "":
		var player_separator = HSeparator.new()
		player_separator.custom_minimum_size = Vector2(0, 4)
		leaderboard_entries_container.add_child(player_separator)
		
		var player_container = HBoxContainer.new()
		player_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_container.custom_minimum_size = Vector2(0, 20)
		
		var rank_label = Label.new()
		rank_label.text = "#" + str(player_position + 1)
		rank_label.custom_minimum_size = Vector2(50, 0)
		rank_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
		
		var player_label = Label.new()
		player_label.text = current_player_id + " (You)"
		player_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
		
		var time_label = Label.new()
		time_label.text = format_time(player_score)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		time_label.custom_minimum_size = Vector2(100, 0)
		time_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
		
		player_container.add_child(rank_label)
		player_container.add_child(player_label)
		player_container.add_child(time_label)
		
		leaderboard_entries_container.add_child(player_container)


func _add_leaderboard_message(message: String) -> void:
	var message_label = Label.new()
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_label.custom_minimum_size = Vector2(0, 80)
	
	leaderboard_entries_container.add_child(message_label)


func format_time(time_seconds: float) -> String:
	if time_seconds <= 0:
		return "--:--:--"
		
	var minutes = floor(time_seconds / 60)
	var seconds = fmod(time_seconds, 60)
	var milliseconds = fmod(time_seconds * 100, 100)
	
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


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
