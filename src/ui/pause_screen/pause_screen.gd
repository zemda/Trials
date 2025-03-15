extends CanvasLayer

@onready var _control_node = $Control
@onready var _continue_button = $Control/CenterContainer/VBoxContainer/ContinueButton
@onready var _restart_button = $Control/CenterContainer/VBoxContainer/RestartButton
@onready var _quit_button = $Control/CenterContainer/VBoxContainer/QuitButton

var _buttons = []
var _current_button_index = 0
var _is_paused = false


func _ready() -> void:
	add_to_group("pause_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_control_node.visible = false
	
	_continue_button.pressed.connect(_on_continue_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	
	_buttons = [_continue_button, _restart_button, _quit_button]


func _input(event: InputEvent) -> void:
	if _is_paused:
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


func show_pause_screen() -> void:
	_is_paused = true
	print("PauseScreen: Showing pause screen")
	_control_node.visible = true
	
	_control_node.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(_control_node, "modulate:a", 1.0, 0.2)
	
	_current_button_index = 0
	_update_button_focus()


func hide_pause_screen() -> void:
	_is_paused = false
	print("PauseScreen: Hiding pause screen")
	
	var tween = create_tween()
	tween.tween_property(_control_node, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	_control_node.visible = false


func _on_continue_pressed() -> void:
	pass


func _on_restart_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()


# func _on_settings_pressed(): # TODO settings screen
#   pass
