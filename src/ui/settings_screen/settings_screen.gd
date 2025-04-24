extends Control

signal settings_closed

@onready var _tabs_container = $VBoxContainer/TabContainer

@onready var _master_volume_slider = $VBoxContainer/TabContainer/Audio/Audio/MasterSlider
@onready var _music_volume_slider = $VBoxContainer/TabContainer/Audio/Audio/MusicSlider
@onready var _sfx_volume_slider = $VBoxContainer/TabContainer/Audio/Audio/SFXSlider

@onready var _fullscreen_check = $VBoxContainer/TabContainer/Video/Video/FullscreenButton
@onready var _vsync_check = $VBoxContainer/TabContainer/Video/Video/VSyncButton
@onready var _resolution_option = $VBoxContainer/TabContainer/Video/Video/ResolutionOption

@onready var _keybind_container = $VBoxContainer/TabContainer/Controls/Controls2/KeybindContainer


var _action_to_change: String = ""
var _button_to_change: Button = null
var _binding_index_to_change: int = -1
var _original_button_text: String = ""
var _previous_resolution_index: int = -1

var _resolutions: Array = [
	Vector2i(1280, 720),   # HD
	Vector2i(1366, 768),   # HD+
	Vector2i(1600, 900),   # HD+
	Vector2i(1920, 1080),  # FHD
	Vector2i(2560, 1440),  # QHD
	Vector2i(3456, 2234),  # 4k Macbook
	Vector2i(3840, 2160),  # 4k
	Vector2i(4112, 2658),  # 4k Macbook
]

var _default_settings: Dictionary = {
	"audio": {
		"master_volume": 0.5,
		"music_volume": 0.5,
		"sfx_volume": 0.5
	},
	"video": {
		"fullscreen": false,
		"vsync": true,
		"resolution_index": -1, # -1 means default
	},
	"controls": {}
}

var _editor_default_inputs: Dictionary = {}

var _current_settings: Dictionary = {}
var _config_path: String = "user://settings.cfg"
var _config: ConfigFile = ConfigFile.new()

var _action_names: Dictionary = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"move_down": "Move Down (e.g., used in wall jumping)",
	"move_up": "Jump",
	"grapple": "Grapple",
	"attach_rope": "Attach to rope",
	"jump_off_rope": "Jump off rope",
	"climb_rope_up": "Climb up rope",
	"climb_rope_down": "Climb down rope",
}

func _ready() -> void:
	visible = false
	
	$BottomButtons/ApplyButton.pressed.connect(_on_apply_pressed)
	$BottomButtons/ResetButton.pressed.connect(_on_reset_pressed)
	$BottomButtons/BackButton.pressed.connect(_on_back_pressed)
	
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	_setup_resolution_dropdown()
	_store_editor_defaults()
	_initialize_current_settings_from_defaults()

	_load_settings()
	_apply_resolution_and_fullscreen()
	_apply_settings_to_ui()


func _input(event: InputEvent) -> void:
	if _action_to_change.is_empty() or not _button_to_change:
		return
		
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
			_cancel_keybind_change()
			get_viewport().set_input_as_handled()
			return
		
		_change_action_binding(_action_to_change, event, _binding_index_to_change)
		_button_to_change.text = _get_event_text(event)
		_button_to_change.set_pressed_no_signal(false)
		
		_action_to_change = ""
		_button_to_change = null
		_binding_index_to_change = -1
		get_viewport().set_input_as_handled()


func _setup_resolution_dropdown() -> void:
	_resolution_option.clear()

	var screen_size = DisplayServer.screen_get_size()
	_resolution_option.add_item("Default", 0)
	
	for i in range(_resolutions.size()):
		var res = _resolutions[i]
		if res.x <= screen_size.x and res.y <= screen_size.y:
			_resolution_option.add_item("%dx%d" % [res.x, res.y], i + 1)
			
	if not _resolution_option.item_selected.is_connected(_on_resolution_selected):
		_resolution_option.item_selected.connect(_on_resolution_selected)


func _store_editor_defaults() -> void:
	for action_name in _action_names.keys():
		_editor_default_inputs[action_name] = []
		var events = InputMap.action_get_events(action_name)
		for event in events:
			var binding = _create_binding_from_event(event)
			if not binding.is_empty():
				_editor_default_inputs[action_name].append(binding)


func _initialize_current_settings_from_defaults() -> void:
	_current_settings.controls = {}
	
	for action_name in _editor_default_inputs.keys():
		_current_settings.controls[action_name] = _editor_default_inputs[action_name].duplicate(true)


func _create_binding_from_event(event: InputEvent) -> Dictionary:
	var binding = {}
	if event is InputEventKey:
		binding["type"] = "key"
		binding["keycode"] = event.physical_keycode
	elif event is InputEventJoypadButton:
		binding["type"] = "joypad"
		binding["button_index"] = event.button_index
	elif event is InputEventMouseButton:
		binding["type"] = "mouse"
		binding["button_index"] = event.button_index
	return binding


func _change_action_binding(action_name: String, event: InputEvent, binding_index: int = -1) -> void:
	if not _current_settings.controls.has(action_name):
		_current_settings.controls[action_name] = []
		
	var binding = _create_binding_from_event(event)
	if binding.is_empty():
		return
		
	var events = InputMap.action_get_events(action_name).duplicate()
	
	if binding_index == -1:
		InputMap.action_add_event(action_name, event)
		_current_settings.controls[action_name].append(binding)
	else:
		InputMap.action_erase_events(action_name)
		
		for i in range(events.size()):
			if i == binding_index:
				InputMap.action_add_event(action_name, event)
			else:
				InputMap.action_add_event(action_name, events[i])
		
		if binding_index < _current_settings.controls[action_name].size():
			_current_settings.controls[action_name][binding_index] = binding
		else:
			_current_settings.controls[action_name].append(binding)
	
	_setup_keybind_ui()


func _cancel_keybind_change() -> void:
	if _button_to_change != null:
		_button_to_change.text = _original_button_text
		_button_to_change.set_pressed_no_signal(false)
		_action_to_change = ""
		_button_to_change = null
		_binding_index_to_change = -1


func show_settings() -> void:
	_refresh_keybinds_display()
	
	_apply_settings_to_ui()
	visible = true
	
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	_tabs_container.grab_focus()


func _refresh_keybinds_display() -> void:
	for action_name in _action_names.keys():
		var events = InputMap.action_get_events(action_name)
		var bindings = []
		
		for event in events:
			var binding = _create_binding_from_event(event)
			if not binding.is_empty():
				bindings.append(binding)
		
		if bindings.size() > 0:
			if not _current_settings.controls.has(action_name) or _current_settings.controls[action_name].size() != bindings.size():
				_current_settings.controls[action_name] = bindings


func hide_settings() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	emit_signal("settings_closed")


func _load_settings() -> void:
	_current_settings = _default_settings.duplicate(true)
	
	if not _current_settings.has("audio"):
		_current_settings.audio = _default_settings.audio.duplicate(true)
	
	if not _current_settings.has("video"):
		_current_settings.video = _default_settings.video.duplicate(true)
	
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
		if _config.has_section_key("video", "resolution_index"):
			_current_settings.video.resolution_index = _config.get_value("video", "resolution_index")
	
	if _config.has_section("controls"):
		for action_name in _action_names.keys():
			if _config.has_section_key("controls", action_name):
				var key_data = _config.get_value("controls", action_name)
				_current_settings.controls[action_name] = key_data

	_apply_settings_to_game()


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
		var action_vbox = VBoxContainer.new()
		action_vbox.add_theme_constant_override("separation", 5)
		
		var name_hbox = HBoxContainer.new()
		var action_label = Label.new()
		action_label.text = _action_names[action_name]
		action_label.add_theme_font_size_override("font_size", 16)
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_hbox.add_child(action_label)
		
		var add_binding_button = Button.new()
		add_binding_button.text = "+"
		add_binding_button.tooltip_text = "Add another binding"
		add_binding_button.add_theme_font_size_override("font_size", 16)
		add_binding_button.pressed.connect(_on_add_binding_pressed.bind(action_name))
		name_hbox.add_child(add_binding_button)
		
		action_vbox.add_child(name_hbox)
		
		var events = InputMap.action_get_events(action_name)
		
		if events.size() == 0:
			var binding_hbox = HBoxContainer.new()
			binding_hbox.add_theme_constant_override("separation", 10)
			
			var no_binding_label = Label.new()
			no_binding_label.text = "No binding set"
			no_binding_label.add_theme_font_size_override("font_size", 16)
			no_binding_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			binding_hbox.add_child(no_binding_label)
			
			action_vbox.add_child(binding_hbox)
		else:
			for i in range(events.size()):
				var binding_hbox = HBoxContainer.new()
				binding_hbox.add_theme_constant_override("separation", 10)
				
				var binding_button = Button.new()
				binding_button.custom_minimum_size = Vector2(130, 0)
				binding_button.text = _get_event_text(events[i])
				binding_button.toggle_mode = true
				binding_button.add_theme_font_size_override("font_size", 16)
				binding_button.pressed.connect(_on_binding_button_pressed.bind(action_name, binding_button, i))
				binding_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				binding_hbox.add_child(binding_button)
				
				var remove_button = Button.new()
				remove_button.text = "x"
				remove_button.tooltip_text = "Remove binding"
				remove_button.add_theme_font_size_override("font_size", 16)
				remove_button.pressed.connect(_on_remove_binding_pressed.bind(action_name, i))
				binding_hbox.add_child(remove_button)
				
				action_vbox.add_child(binding_hbox)
		
		_keybind_container.add_child(action_vbox)


func _get_event_text(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventJoypadButton:
		return "Joypad " + str(event.button_index)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle" 
			MOUSE_BUTTON_WHEEL_UP: return "Mouse Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Mouse Wheel Down"
			_: return "Mouse " + str(event.button_index)
	return "Unknown"


func _apply_settings_to_ui() -> void:
	_master_volume_slider.value = _current_settings.audio.master_volume * 100
	_music_volume_slider.value = _current_settings.audio.music_volume * 100
	_sfx_volume_slider.value = _current_settings.audio.sfx_volume * 100
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(_current_settings.audio.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(_current_settings.audio.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(_current_settings.audio.sfx_volume))
	
	_fullscreen_check.button_pressed = _current_settings.video.fullscreen
	_vsync_check.button_pressed = _current_settings.video.vsync
	
	if _current_settings.video.resolution_index == -1:
		_resolution_option.selected = 0
	else:
		_resolution_option.selected = _current_settings.video.resolution_index
	
	_setup_keybind_ui()


func _apply_settings_to_game() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(_current_settings.audio.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(_current_settings.audio.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(_current_settings.audio.sfx_volume))

	_apply_resolution_and_fullscreen()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if 
		_current_settings.video.vsync else DisplayServer.VSYNC_DISABLED)
	
	for action_name in _current_settings.controls.keys():
		var key_data = _current_settings.controls[action_name]
		_apply_keybinds(action_name, key_data)


func _apply_resolution_and_fullscreen() -> void:
	if _current_settings.video.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	var resolution_index = _current_settings.video.resolution_index
	var screen_size = DisplayServer.screen_get_size()
	
	if resolution_index == -1 or resolution_index == 0:
		var half_size = Vector2i((screen_size.y / 18) * 16, screen_size.y / 2)
		DisplayServer.window_set_size(half_size)
	else:
		if resolution_index > 0 and resolution_index <= _resolutions.size():
			var target_res = _resolutions[resolution_index - 1]
			if target_res.x <= screen_size.x and target_res.y <= screen_size.y:
				DisplayServer.window_set_size(target_res)
			else:
				var half_size = Vector2i((screen_size.y / 18) * 16, screen_size.y / 2)
				DisplayServer.window_set_size(half_size)
				_current_settings.video.resolution_index = 0
				if _resolution_option:
					_resolution_option.selected = 0
	
	if not _current_settings.video.fullscreen:
		DisplayServer.window_set_position(DisplayServer.screen_get_position() + 
			(DisplayServer.screen_get_size() - DisplayServer.window_get_size()) / 2)


func _apply_keybinds(action_name: String, key_data_array) -> void:
	var data_array = []
	
	if key_data_array is Dictionary:
		if not key_data_array.is_empty():
			data_array = [key_data_array]
	elif key_data_array is Array:
		data_array = key_data_array
	else:
		return
	
	if data_array.size() == 0:
		return
		
	InputMap.action_erase_events(action_name)
	
	for key_data in data_array:
		if key_data.is_empty():
			continue
			
		if key_data["type"] == "key":
			var event = InputEventKey.new()
			event.physical_keycode = key_data["keycode"]
			InputMap.action_add_event(action_name, event)
		elif key_data["type"] == "joypad":
			var event = InputEventJoypadButton.new()
			event.button_index = key_data["button_index"]
			InputMap.action_add_event(action_name, event)
		elif key_data["type"] == "mouse":
			var event = InputEventMouseButton.new()
			event.button_index = key_data["button_index"]
			InputMap.action_add_event(action_name, event)


func _get_settings_from_ui() -> void:
	_current_settings.audio.master_volume = _master_volume_slider.value / 100.0
	_current_settings.audio.music_volume = _music_volume_slider.value / 100.0
	_current_settings.audio.sfx_volume = _sfx_volume_slider.value / 100.0
	
	_current_settings.video.fullscreen = _fullscreen_check.button_pressed
	_current_settings.video.vsync = _vsync_check.button_pressed
	_current_settings.video.resolution_index = _resolution_option.selected


func _on_apply_pressed() -> void:
	_get_settings_from_ui()
	_save_settings()


func _on_reset_pressed() -> void:
	if FileAccess.file_exists(_config_path):
			var dir = DirAccess.open("user://")
			if dir:
				dir.remove(_config_path)
	for action_name in _action_names.keys():
		InputMap.action_erase_events(action_name)
		_current_settings.controls[action_name] = _editor_default_inputs[action_name].duplicate(true)
		_apply_keybinds(action_name, _editor_default_inputs[action_name])
	
	_current_settings.audio = _default_settings.audio.duplicate(true)
	_current_settings.video = _default_settings.video.duplicate(true)
	
	_apply_settings_to_ui()
	_apply_settings_to_game()


func _on_back_pressed() -> void:
	hide_settings()


func _on_resolution_selected(index: int) -> void:
	_previous_resolution_index = _current_settings.video.resolution_index
	_current_settings.video.resolution_index = index
	
	_apply_resolution_and_fullscreen()
	_save_settings()
	
	
func _on_fullscreen_toggled(toggled_on: bool) -> void:
	_current_settings.video.fullscreen = toggled_on
	_apply_resolution_and_fullscreen()
	_save_settings()


func _on_binding_button_pressed(action_name: String, button: Button, binding_index: int) -> void:
	if _action_to_change == action_name and _binding_index_to_change == binding_index:
		_cancel_keybind_change()
		return
		
	if _button_to_change != null:
		_button_to_change.text = _original_button_text
		_button_to_change.set_pressed_no_signal(false)
	
	_action_to_change = action_name
	_button_to_change = button
	_binding_index_to_change = binding_index
	_original_button_text = button.text
	button.text = "Press any key..."


func _on_add_binding_pressed(action_name: String) -> void:
	var temp_button = Button.new()
	temp_button.text = "Press any key..."
	temp_button.visible = false
	add_child(temp_button)
	
	_action_to_change = action_name
	_button_to_change = temp_button
	_binding_index_to_change = -1  # -1 means add new binding
	_original_button_text = ""


func _on_remove_binding_pressed(action_name: String, binding_index: int) -> void:
	var events = InputMap.action_get_events(action_name)
	
	if binding_index >= 0 and binding_index < events.size():
		InputMap.action_erase_event(action_name, events[binding_index])
		
		if _current_settings.controls.has(action_name) and binding_index < _current_settings.controls[action_name].size():
			_current_settings.controls[action_name].remove_at(binding_index)
	
	_setup_keybind_ui()
