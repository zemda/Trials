extends CanvasLayer

@onready var _progress_bar := $Control/CenterContainer/VBoxContainer/ProgressBar
@onready var _loading_text := $Control/CenterContainer/VBoxContainer/LoadingText
@onready var _control_node := $Control
@onready var _panel := $Control/Panel

var _current_progress: float = 0.0
var _target_progress: float = 0.0
var _progress_tween: Tween
var _dot_timer: Timer
var _dot_count: int = 0


func _ready() -> void:
	add_to_group("loading_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	_dot_timer = Timer.new()
	_dot_timer.wait_time = 0.4
	_dot_timer.timeout.connect(_animate_dots)
	add_child(_dot_timer)
	
	_progress_bar.show_percentage = true


func _process(delta: float) -> void:
	if visible and _current_progress < _target_progress:
		_current_progress = min(_current_progress + delta * 30.0, _target_progress)
		_progress_bar.value = _current_progress


func show_loading_screen() -> void:
	visible = true
	layer = 128
	
	_current_progress = 0.0
	_target_progress = 0.0
	_progress_bar.value = 0
	
	_loading_text.text = "LOADING..."
	_dot_count = 0
	_dot_timer.start()
	
	_control_node.modulate.a = 1.0


func hide_loading_screen() -> void:
	_dot_timer.stop()
	
	if _progress_tween and _progress_tween.is_valid():
		_progress_tween.kill()
	
	var tween = create_tween()
	tween.tween_property(_control_node, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	visible = false


func update_progress(value: float) -> void:
	var percent = value
	if value <= 1.0:
		percent = value * 100
	
	_target_progress = percent
	
	if abs(_target_progress - _current_progress) > 5.0:
		if _progress_tween and _progress_tween.is_valid():
			_progress_tween.kill()
		
		_progress_tween = create_tween()
		_progress_tween.tween_property(self, "_current_progress", _target_progress, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		_progress_tween.tween_callback(func(): _progress_bar.value = _current_progress)


func _animate_dots() -> void:
	_dot_count = (_dot_count + 1) % 4
	var dots = ""
	for i in range(_dot_count):
		dots += "."
	_loading_text.text = "LOADING" + dots
