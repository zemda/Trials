extends Control

@onready var level_select_option = $PanelContainer/MarginContainer/VBoxContainer/LevelSelectContainer/LevelSelectOption
@onready var leaderboard_entries_container = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/EntriesContainer
@onready var refresh_button = $PanelContainer/MarginContainer/VBoxContainer/LevelSelectContainer/RefreshButton
@onready var loading_label = $PanelContainer/MarginContainer/VBoxContainer/LoadingLabel
@onready var back_button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

signal back_pressed


func _ready() -> void:
	refresh_button.pressed.connect(_on_refresh_pressed)
	level_select_option.item_selected.connect(_on_level_selected)
	back_button.pressed.connect(_on_back_pressed)
	
	_configure_layout()


func initialize() -> void:
	_populate_level_select()
	_configure_layout()
	
	for child in leaderboard_entries_container.get_children():
		child.queue_free()
		
	_refresh_leaderboard()


func _configure_layout() -> void:
	var vbox = $PanelContainer/MarginContainer/VBoxContainer
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	
	var scroll = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 150)
	
	leaderboard_entries_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	back_button.size_flags_vertical = Control.SIZE_SHRINK_END
	back_button.custom_minimum_size = Vector2(0, 40)
	back_button.focus_mode = Control.FOCUS_ALL
	
	back_button.add_theme_color_override("font_color", Color(1, 1, 1))
	back_button.add_theme_color_override("font_hover_color", Color(0.8, 0.8, 1))
	
	var panel = $PanelContainer
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var margin = $PanelContainer/MarginContainer
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.custom_minimum_size = Vector2(0, 20)
	
	size = get_viewport().get_visible_rect().size


func _populate_level_select() -> void:
	level_select_option.clear()
	
	var leaderboards = LeaderboardManager.get_all_leaderboards()
	
	for i in range(leaderboards.size()):
		level_select_option.add_item(leaderboards[i].name, i)


func _refresh_leaderboard() -> void:
	loading_label.visible = true
	
	for child in leaderboard_entries_container.get_children():
		child.queue_free()
	
	var selected_id = level_select_option.get_selected_id()
	var leaderboard_name = ""
	
	var leaderboards = LeaderboardManager.get_all_leaderboards()
	if selected_id >= 0 and selected_id < leaderboards.size():
		leaderboard_name = leaderboards[selected_id].id
	else:
		leaderboard_name = LeaderboardManager.GAME_COMPLETION_LEADERBOARD
	
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
	if entries.size() == 0 or (entries.size() == 1 and entries[0].score > 999000):
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
	
	var filtered_entries = []
	for entry in entries:
		if entry.score < 999000:
			filtered_entries.append(entry)
	
	if filtered_entries.size() == 0:
		_add_leaderboard_message("No entries found. Be the first to complete!")
		return
	
	for i in range(min(10, filtered_entries.size())):
		var entry = filtered_entries[i]
		
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


func _on_back_pressed() -> void:
	emit_signal("back_pressed")
