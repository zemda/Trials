extends Area2D
class_name HookPoint

@export_range(0.0, 1.0) var one_time_use_chance: float = 0.5
@export var is_one_time_use: bool = true
@export_range(1, 100) var x_scale: int = 1

@export_category("Visual Settings")
@export_range(1.0, 10.0) var line_height: float = 8.0:
	set(value):
		line_height = value
		if _shader_material:
			_shader_material.set_shader_parameter("line_height", value)
@export var base_color: Color = Color(0.4, 0.7, 1.0, 1.0):
	set(value):
		base_color = value
		if _shader_material:
			_shader_material.set_shader_parameter("base_color", value)
@export var glow_color: Color = Color(0.6, 0.9, 1.0, 0.8):
	set(value):
		glow_color = value
		if _shader_material:
			_shader_material.set_shader_parameter("glow_color", value)
@export_range(0.5, 5.0) var glow_intensity: float = 0.5:
	set(value):
		glow_intensity = value
		if _shader_material:
			_shader_material.set_shader_parameter("glow_intensity", value)
@export_range(0.01, 0.3) var glow_width: float = 0.3:
	set(value):
		glow_width = value
		if _shader_material:
			_shader_material.set_shader_parameter("glow_width", value)
@export_range(0.1, 5.0) var pulse_speed: float = 1.5:
	set(value):
		pulse_speed = value
		if _shader_material:
			_shader_material.set_shader_parameter("pulse_speed", value)
@export_range(0.1, 5.0) var shimmer_speed: float = 0.5:
	set(value):
		shimmer_speed = value
		if _shader_material:
			_shader_material.set_shader_parameter("shimmer_speed", value)


var _current_anchor: Area2D = null
var _marked_for_removal: bool = false
var _shader_material: ShaderMaterial = null
var _visual: ColorRect = null

const SHADER_PATH = "res://assets/shaders/hook_point.gdshader"


func _init() -> void:
	add_to_group("Hookable")
	if is_one_time_use:
		add_to_group("storable")


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	scale.x = x_scale
	
	_create_visual()
	_update_shader_parameters()


func _create_visual() -> void:
	if _visual != null:
		_visual.queue_free()
	
	_visual = ColorRect.new()
	_visual.size = Vector2(14, 10)
	_visual.position = Vector2(1, -1)
	
	var shader = load(SHADER_PATH)
	if shader:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		_visual.material = _shader_material
	
	add_child(_visual)


func _update_shader_parameters() -> void:
	if _shader_material:
		var params = {
			"base_color": base_color,
			"glow_color": glow_color,
			"line_height": line_height,
			"glow_intensity": glow_intensity,
			"glow_width": glow_width,
			"pulse_speed": pulse_speed,
			"shimmer_speed": shimmer_speed
		}
		
		for param in params:
			_shader_material.set_shader_parameter(param, params[param])


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("grapple_anchor"):
		_handle_anchor_entered(area)


func _handle_anchor_entered(anchor: Node2D) -> void:
	_current_anchor = anchor
	
	if _shader_material:
		_shader_material.set_shader_parameter("glow_intensity", glow_intensity * 1.5)
	
	if is_one_time_use:
		_marked_for_removal = randf() < one_time_use_chance
		if _marked_for_removal and _shader_material:
			_shader_material.set_shader_parameter("glow_color", Color(1.0, 0.7, 0.8, 0.8))


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("grapple_anchor") and area == _current_anchor:
		_handle_anchor_exited()


func _handle_anchor_exited() -> void:
	if _shader_material and !_marked_for_removal:
		_shader_material.set_shader_parameter("glow_intensity", glow_intensity)
		_shader_material.set_shader_parameter("glow_color", glow_color)

	if _marked_for_removal:
		_create_break_effect()
		queue_free()
	
	_current_anchor = null
	_marked_for_removal = false


func _create_break_effect() -> void:
	var particles = CPUParticles2D.new()
	particles.position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 12
	particles.lifetime = 0.7
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.gravity = Vector2(0, 100)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 80
	particles.scale_amount_min = 1
	particles.scale_amount_max = 3
	particles.color = base_color
	
	get_tree().current_scene.add_child(particles)
	
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	particles.add_child(timer)
	timer.timeout.connect(func(): particles.queue_free())
	timer.start()
