extends Control

@onready var levels_grid = $PanelContainer/MarginContainer/VBoxContainer/LevelsGrid
@onready var best_run_label = $PanelContainer/MarginContainer/VBoxContainer/BestRunLabel
@onready var back_button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

signal back_pressed

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

func update_stats() -> void:
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

func format_time(time_seconds: float) -> String:
	if time_seconds <= 0:
		return "--:--:--"
		
	var minutes = floor(time_seconds / 60)
	var seconds = fmod(time_seconds, 60)
	var milliseconds = fmod(time_seconds * 100, 100)
	
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func _on_back_pressed() -> void:
	emit_signal("back_pressed")
