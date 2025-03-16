extends CanvasLayer

@onready var _progress_bar := $Control/CenterContainer/VBoxContainer/ProgressBar
@onready var _loading_text := $Control/CenterContainer/VBoxContainer/LoadingText
@onready var _control_node := $Control
@onready var _panel := $Control/Panel


func _ready():
	add_to_group("loading_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_loading_screen():
	visible = true
	layer = 128
	
	_control_node.modulate.a = 1.0
	_progress_bar.value = 0
	
	_loading_text.text = "LOADING..."


func hide_loading_screen():
	visible = false
	var tween = create_tween()
	tween.tween_property(_control_node, "modulate:a", 0.0, 0.3)
	await tween.finished


func update_progress(value: float):
	var percent = value
	if value <= 1.0:
		percent = value * 100
	
	_progress_bar.value = percent
