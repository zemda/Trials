extends Control

@onready var run_time_label = $VBoxContainer/RunTimeLabel
@onready var best_run_time_label = $VBoxContainer/BestRunTimeLabel

var current_level: String = ""


func _ready() -> void:
	GameManager.connect("level_loaded", Callable(self, "_on_level_loaded"))
	GameManager.connect("level_started", Callable(self, "_on_level_started"))
	GameManager.connect("run_completed", Callable(self, "_on_run_completed"))
	
	current_level = GameManager.current_level
	
	_update_all_labels()


func _process(_delta: float) -> void:
	if GameManager.current_level != "":
		_update_run_time_label()


func _update_all_labels() -> void:
	_update_run_time_label()
	_update_best_run_time_label()


func _update_run_time_label() -> void:
	var run_time = GameManager.get_current_run_time()
	run_time_label.text = "Run: " + format_time(run_time)
	run_time_label.visible = true


func _update_best_run_time_label() -> void:
	var best_run_time = GameManager.get_best_run_time()
	if best_run_time > 0:
		best_run_time_label.text = "Best Run: " + format_time(best_run_time)
	else:
		best_run_time_label.text = "Best Run: --:--:--"
	
	best_run_time_label.visible = true


func _on_level_loaded() -> void:
	current_level = GameManager.current_level
	_update_all_labels()


func _on_level_started() -> void:
	_update_all_labels()


func _on_run_completed(_run_time: float) -> void:
	_update_best_run_time_label()


func format_time(time_seconds: float) -> String:
	var minutes = floor(time_seconds / 60)
	var seconds = fmod(time_seconds, 60)
	var milliseconds = fmod(time_seconds * 100, 100)
	
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
