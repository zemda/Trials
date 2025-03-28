extends Area2D

signal area_level_completed

@export var is_final_level: bool = false
@export_range(0.5, 10.0) var scale_factor: float = 1.0
@export var normal_color: Color = Color(0.3, 0.7, 1.0, 1.0)
@export var final_color: Color = Color(0.3, 1.0, 0.3, 1.0)

const SHADER_PATH_CHECKER = "res://assets/shaders/checker_pattern.gdshader"
const SHADER_PATH_RING = "res://assets/shaders/ring_of_power.gdshader"
const SHADER_PATH_GLOW = "res://assets/shaders/background_glow.gdshader"

func _ready() -> void:
	add_to_group("level_exit")
	body_entered.connect(_on_body_entered)
	
	await get_tree().process_frame
	var lm = get_parent()
	lm.register_level_completed(self)
	
	_create_visuals()


func _create_visuals() -> void:
	_clear_visuals()
	
	var area_color = final_color if is_final_level else normal_color
	var base_size = max(60, 60 * scale_factor)
	
	var checker_size = base_size
	var ring_size = base_size * 1.4
	var glow_size = base_size * 1.8
	
	_add_background_glow(area_color, glow_size)
	_add_checker_area(area_color, checker_size)
	_add_power_ring(area_color, ring_size)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		emit_signal("area_level_completed")


func _clear_visuals() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			continue
		child.queue_free()


func _add_background_glow(color: Color, size: float) -> void:
	var glow = ColorRect.new()
	glow.name = "BackgroundGlow"
	var glow_size = size * 2
	glow.size = Vector2(glow_size, glow_size)
	glow.position = Vector2(-glow_size/2, -glow_size/2)
	glow.color = color
	glow.z_index = -1
	add_child(glow)
	
	var shader = load(SHADER_PATH_GLOW)
	if shader:
		var _material = ShaderMaterial.new()
		_material.shader = shader
		_material.set_shader_parameter("color", color)
		_material.set_shader_parameter("glow_radius", 0.4)
		_material.set_shader_parameter("glow_intensity", 0.5)
		glow.material = _material


func _add_checker_area(color: Color, size: float) -> void:
	var checker = ColorRect.new()
	checker.name = "CheckerArea"
	checker.size = Vector2(size, size)
	checker.position = Vector2(-size/2, -size/2)
	checker.color = color
	checker.z_index = 0
	add_child(checker)
	
	var shader = load(SHADER_PATH_CHECKER)
	if shader:
		var _material = ShaderMaterial.new()
		_material.shader = shader
		_material.set_shader_parameter("color", color)
		_material.set_shader_parameter("background_color", Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, color.a))
		_material.set_shader_parameter("checker_size", 20.0 * scale_factor)
		_material.set_shader_parameter("time_scale", 5.0)
		_material.set_shader_parameter("alpha", 0.9)
		checker.material = _material


func _add_power_ring(color: Color, size: float) -> void:
	var ring = ColorRect.new()
	ring.name = "PowerRing"
	ring.size = Vector2(size, size)
	ring.position = Vector2(-size/2, -size/2)
	ring.color = color
	ring.z_index = 1
	add_child(ring)
	
	var noise_tex = _create_noise_texture(FastNoiseLite.TYPE_VALUE_CUBIC, 256, 0.1)
	
	var shader = load(SHADER_PATH_RING)
	if shader:
		var _material = ShaderMaterial.new()
		_material.shader = shader
		
		_material.set_shader_parameter("radius", 0.85)
		_material.set_shader_parameter("thickness", 0.08)
		_material.set_shader_parameter("color", color)
		_material.set_shader_parameter("brightness", 2.0)
		_material.set_shader_parameter("angular_speed", 1.5)
		_material.set_shader_parameter("radial_speed", 0.7)
		_material.set_shader_parameter("alpha", 1.0)
		_material.set_shader_parameter("noise", noise_tex)
		
		ring.material = _material


func _create_noise_texture(noise_type: int, size: int, freq: float) -> NoiseTexture2D:
	var noise_tex = NoiseTexture2D.new()
	noise_tex.width = size
	noise_tex.height = size
	noise_tex.seamless = true
	
	var noise = FastNoiseLite.new()
	noise.noise_type = noise_type
	noise.frequency = freq
	
	noise_tex.noise = noise
	
	return noise_tex
