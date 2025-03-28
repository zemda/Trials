extends Node
class_name EndScreen

var player_instance: Player
var screen_size
var player_velocity: Vector2 = Vector2(200, 150)
var rotation_speed: float = 1.5
var can_restart: bool = false

const TITLE_TEXT: String = "CONGRATULATIONS?"
const MESSAGE_TEXT: String = "You've completed the game! Or have you...?\n\nThe victory was a lie.\nThe cake was a lie.\nYour freedom was a lie."
const RESTART_TEXT: String = "[ press any key... ]"

var title_colors: Array = [
	Color("#ffffff"),
	Color("#dddddd"),
	Color("#aaaaaa"),
	Color("#ffffff")
]


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	
	_setup_background_shaders()
	_setup_text()
	_setup_player()
	_setup_restart_label_effects()
	
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(_open_rickroll_and_minimize)


func _input(event: InputEvent) -> void:
	if can_restart and event is InputEventKey and event.pressed:
		GameManager.restart_game()


func _process(delta: float) -> void:
	if is_instance_valid(player_instance):
		player_instance.global_position += player_velocity * delta
		
		player_instance.rotation += rotation_speed * delta
		
		if player_instance.global_position.x < 20 or player_instance.global_position.x > screen_size.x - 20:
			player_velocity.x = -player_velocity.x
			_add_bounce_effect()
			
		if player_instance.global_position.y < 20 or player_instance.global_position.y > screen_size.y - 20:
			player_velocity.y = -player_velocity.y
			_add_bounce_effect()


func _setup_background_shaders() -> void:
	var back_material = ShaderMaterial.new()
	var back_shader = load("res://assets/shaders/background_shader.gdshader")
	
	back_material.shader = back_shader
	back_material.set_shader_parameter("scroll_speed", 0.15)
	back_material.set_shader_parameter("depth_effect", 1.5)
	$Background/ColorRect.material = back_material


func _setup_text() -> void:
	var title = $MainContent/VBoxContainer/TitleLabel
	
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 8)
	title.pivot_offset = title.size / 2
	
	var title_tween = create_tween().set_loops()
	title_tween.tween_property(title, "scale", Vector2(1.1, 1.1), 0.5).from(Vector2(1.0, 1.0))
	title_tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.5)
	
	var color_tween = create_tween().set_loops()
	for color in title_colors:
		color_tween.tween_property(title, "modulate", color, 0.3)
	
	var message = $MainContent/VBoxContainer/MessageLabel
	message.text = MESSAGE_TEXT
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 28)
	message.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	message.add_theme_constant_override("outline_size", 4)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var gametime = $MainContent/VBoxContainer/GameTimeLabel
	gametime.text = "Your current run time was: %0.2f seconds" % [GameManager.get_current_run_time()]
	gametime.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gametime.add_theme_font_size_override("font_size", 22)
	gametime.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	gametime.add_theme_constant_override("outline_size", 2)
	gametime.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	
	var restart = $MainContent/VBoxContainer/RestartLabel
	restart.text = RESTART_TEXT
	restart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart.add_theme_font_size_override("font_size", 24)
	restart.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	restart.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	restart.add_theme_constant_override("outline_size", 3)
	restart.pivot_offset = restart.size / 2


func _setup_restart_label_effects() -> void:
	var restart = $MainContent/VBoxContainer/RestartLabel
	restart.modulate.a = 0.0
	
	var fade_tween = create_tween().set_loops()
	fade_tween.tween_property(restart, "modulate:a", 1.0, 0.8)
	fade_tween.tween_property(restart, "modulate:a", 0.2, 0.8)
	
	var color_tween = create_tween().set_loops()
	color_tween.tween_property(restart, "theme_override_colors/font_color", Color(0.4, 1.0, 0.4, 1.0), 1.5)
	color_tween.tween_property(restart, "theme_override_colors/font_color", Color(0.2, 0.8, 0.2, 1.0), 1.5)
	
	var scale_tween = create_tween().set_loops()
	scale_tween.tween_property(restart, "scale", Vector2(1.05, 1.05), 1.2)
	scale_tween.tween_property(restart, "scale", Vector2(1.0, 1.0), 1.2)


func _setup_player() -> void:
	player_instance = GameManager.get_player()
	
	GameManager.disable_player_input()
	
	player_instance.visible = true
	player_instance.global_position = Vector2(screen_size.x / 2, screen_size.y / 2)
	
	player_instance.set_process(true)
	player_instance.z_index = 10
	
	player_velocity = Vector2(min(screen_size.x, screen_size.y) * 0.4, min(screen_size.x, screen_size.y) * 0.3)


func _open_rickroll_and_minimize() -> void:
	OS.shell_open("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
	await get_tree().create_timer(0.1).timeout
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	await get_tree().create_timer(1.0).timeout
	can_restart = true


func _add_bounce_effect() -> void:
	player_velocity = player_velocity.rotated(randf_range(-0.3, 0.3))
	
	var speed = player_velocity.length()
	if speed < 150:
		player_velocity = player_velocity.normalized() * 150
	
	if randf() > 0.7:
		rotation_speed = -rotation_speed * randf_range(0.8, 1.5)
