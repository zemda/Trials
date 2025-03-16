extends Control

signal settings_closed

@onready var _tabs_container = $VBoxContainer/TabContainer

@onready var _master_volume_slider = $VBoxContainer/TabContainer/Audio/Audio/MasterSlider
@onready var _music_volume_slider = $VBoxContainer/TabContainer/Audio/Audio/MusicSlider
@onready var _sfx_volume_slider = $VBoxContainer/TabContainer/Audio/Audio/SFXSlider

@onready var _fullscreen_check = $VBoxContainer/TabContainer/Video/Video/FullscreenButton
@onready var _vsync_check = $VBoxContainer/TabContainer/Video/Video/VSyncButton

@onready var _keybind_container = $VBoxContainer/TabContainer/Controls/Controls2/KeybindContainer


var _action_to_change: String = ""
var _button_to_change: Button = null

var _default_settings: Dictionary = {
	"audio": {
		"master_volume": 0.8,
		"music_volume": 0.7,
		"sfx_volume": 0.8
	},
	"video": {
		"fullscreen": false,
		"vsync": true,
	},
	"controls": {}
}

var _current_settings: Dictionary = {}
var _config_path: String = "user://settings.cfg"
var _config: ConfigFile = ConfigFile.new()

var _action_names: Dictionary = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"jump": "Jump",
	"grapple": "Grapple",
	"pause": "Pause",
}


func _ready() -> void:
	visible = false
	
	$BottomButtons/ApplyButton.pressed.connect(_on_apply_pressed)
	$BottomButtons/ResetButton.pressed.connect(_on_reset_pressed)
	$BottomButtons/BackButton.pressed.connect(_on_back_pressed)
	
	_setup_keybind_ui()
	
	_load_settings()
	_apply_settings_to_ui()


func _input(event: InputEvent) -> void:
	if _action_to_change.is_empty() or _button_to_change == null:
		return
	if event is InputEventKey or event is InputEventJoypadButton:
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			_cancel_keybind_change()
			get_viewport().set_input_as_handled()
			return
		
		_change_action_binding(_action_to_change, event)
		_button_to_change.text = _get_action_key_text(_action_to_change)
		_button_to_change.set_pressed_no_signal(false)
		
		_action_to_change = ""
		_button_to_change = null
		get_viewport().set_input_as_handled()


func show_settings() -> void:
	_load_settings()
	_apply_settings_to_ui()
	visible = true
	
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	_tabs_container.grab_focus()


func hide_settings() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	emit_signal("settings_closed")


func _change_action_binding(action_name: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	
	if not _current_settings.controls.has(action_name):
		_current_settings.controls[action_name] = {}
	
	if event is InputEventKey:
		_current_settings.controls[action_name]["type"] = "key"
		_current_settings.controls[action_name]["keycode"] = event.keycode
	elif event is InputEventJoypadButton:
		_current_settings.controls[action_name]["type"] = "joypad"
		_current_settings.controls[action_name]["button_index"] = event.button_index


func _cancel_keybind_change() -> void:
	if _button_to_change != null:
		_button_to_change.set_pressed_no_signal(false)
		_action_to_change = ""
		_button_to_change = null


func _load_settings() -> void:
	_current_settings = _default_settings.duplicate(true)
	
	var error = _config.load(_config_path)
	if error != OK:
		return
	
	if _config.has_section("audio"):
		if _config.has_section_key("audio", "master_volume"):
			_current_settings.audio.master_volume = _config.get_value("audio", "master_volume")
		if _config.has_section_key("audio", "music_volume"):
			_current_settings.audio.music_volume = _config.get_value("audio", "music_volume")
		if _config.has_section_key("audio", "sfx_volume"):
			_current_settings.audio.sfx_volume = _config.get_value("audio", "sfx_volume")
	
	if _config.has_section("video"):
		if _config.has_section_key("video", "fullscreen"):
			_current_settings.video.fullscreen = _config.get_value("video", "fullscreen")
		if _config.has_section_key("video", "vsync"):
			_current_settings.video.vsync = _config.get_value("video", "vsync")
	
	if _config.has_section("controls"):
		for action_name in _action_names.keys():
			if _config.has_section_key("controls", action_name):
				var key_data = _config.get_value("controls", action_name)
				_current_settings.controls[action_name] = key_data
				_apply_keybind(action_name, key_data)


func _save_settings() -> void:
	for key in _current_settings.audio.keys():
		_config.set_value("audio", key, _current_settings.audio[key])
	
	for key in _current_settings.video.keys():
		_config.set_value("video", key, _current_settings.video[key])
	
	for action_name in _current_settings.controls.keys():
		_config.set_value("controls", action_name, _current_settings.controls[action_name])
	
	_config.save(_config_path)
	
	_apply_settings_to_game()


func _setup_keybind_ui() -> void:
	for child in _keybind_container.get_children():
		child.queue_free()
	
	_keybind_container.add_theme_constant_override("separation", 15)
	_keybind_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	for action_name in _action_names.keys():
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 50)
		hbox.size_flags_horizontal = Control.SIZE_FILL
		
		var label = Label.new()
		label.text = _action_names[action_name]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(100, 0)
		button.text = _get_action_key_text(action_name)
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size", 16)
		
		button.pressed.connect(_on_keybind_button_pressed.bind(action_name, button))
		
		hbox.add_child(label)
		hbox.add_child(button)
		
		_keybind_container.add_child(hbox)


func _get_action_key_text(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		var event = events[0]
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
		elif event is InputEventJoypadButton:
			return "Joypad Button " + str(event.button_index)
	return "Unassigned"


func _apply_settings_to_ui() -> void:
	_master_volume_slider.value = _current_settings.audio.master_volume * 100
	_music_volume_slider.value = _current_settings.audio.music_volume * 100
	_sfx_volume_slider.value = _current_settings.audio.sfx_volume * 100
	
	_fullscreen_check.button_pressed = _current_settings.video.fullscreen
	_vsync_check.button_pressed = _current_settings.video.vsync
	
	for button in _keybind_container.get_children():
		if button is HBoxContainer:
			var action_label = button.get_child(0) as Label
			var action_button = button.get_child(1) as Button
			
			for action_name in _action_names.keys():
				if action_label.text == _action_names[action_name]:
					action_button.text = _get_action_key_text(action_name)


func _apply_settings_to_game() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
		_current_settings.audio.master_volume) # add others
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if 
		_current_settings.video.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if 
		_current_settings.video.vsync else DisplayServer.VSYNC_DISABLED)
	
	for action_name in _current_settings.controls.keys():
		var key_data = _current_settings.controls[action_name]
		_apply_keybind(action_name, key_data)


func _apply_keybind(action_name: String, key_data: Dictionary) -> void:
	if key_data.is_empty():
		return
	
	InputMap.action_erase_events(action_name)
	
	if key_data["type"] == "key":
		var event = InputEventKey.new()
		event.keycode = key_data["keycode"]
		InputMap.action_add_event(action_name, event)
	elif key_data["type"] == "joypad":
		var event = InputEventJoypadButton.new()
		event.button_index = key_data["button_index"]
		InputMap.action_add_event(action_name, event)


func _get_settings_from_ui() -> void:
	_current_settings.audio.master_volume = _master_volume_slider.value / 100.0
	_current_settings.audio.music_volume = _music_volume_slider.value / 100.0
	_current_settings.audio.sfx_volume = _sfx_volume_slider.value / 100.0
	
	_current_settings.video.fullscreen = _fullscreen_check.button_pressed
	_current_settings.video.vsync = _vsync_check.button_pressed


func _on_apply_pressed() -> void:
	_get_settings_from_ui()
	_save_settings()
	

func _on_reset_pressed() -> void:
	_current_settings = _default_settings.duplicate(true)
	_apply_settings_to_ui()
	_apply_settings_to_game()
	

func _on_back_pressed() -> void:
	hide_settings()


func _on_keybind_button_pressed(action_name: String, button: Button) -> void:
	if _action_to_change == action_name:
		_cancel_keybind_change()
		return
		
	if _button_to_change != null:
		_button_to_change.set_pressed_no_signal(false)
	
	_action_to_change = action_name
	_button_to_change = button
	button.text = "Press any key..."
