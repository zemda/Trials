extends CanvasLayer

var _progress_bar: ProgressBar
var _loading_text: Label
var _control_node: Control
var _panel: Panel

var _is_ready: bool = false

func _ready():
	add_to_group("loading_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_progress_bar = $Control/CenterContainer/VBoxContainer/ProgressBar
	_loading_text = $Control/CenterContainer/VBoxContainer/LoadingText
	_control_node = $Control
	_panel = $Control/Panel
	
	_is_ready = true
	
	if _control_node.visible == true:
		_progress_bar.value = 0
		_loading_text.text = "LOADING..."
	else:
		_control_node.visible = false
	
	if SceneChanger.has_signal("progress_changed"):
		SceneChanger.connect("progress_changed", Callable(self, "update_progress"))


func show_loading_screen():
	if !_is_ready:
		return
	
	layer = 128
	
	_control_node.visible = true
	_control_node.modulate.a = 1.0
	_progress_bar.value = 0
	
	_loading_text.text = "LOADING..."


func hide_loading_screen():
	if !_is_ready:
		return
	
	var tween = create_tween()
	tween.tween_property(_control_node, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	_control_node.visible = false


func update_progress(value: float):
	if !_is_ready:
		return
		
	var percent = value
	if value <= 1.0:
		percent = value * 100
	
	_progress_bar.value = percent
