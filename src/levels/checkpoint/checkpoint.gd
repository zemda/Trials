extends Area2D
class_name Checkpoint

signal checkpoint_activated(checkpoint)

#region Vars
@export_category("Checkpoint Settings")
@export var checkpoint_id: String = ""
@export var active_color: Color = Color(0.0, 1.0, 0.0, 1.0):
	set(value):
		active_color = value
		if _shader_material and _is_latest_checkpoint:
			_shader_material.set_shader_parameter("glow_color", value)
			_update_particles_color(value)
@export var inactive_color: Color = Color(1.0, 0.0, 0.0, 1.0):
	set(value):
		inactive_color = value
		if _shader_material and !_is_active:
			_shader_material.set_shader_parameter("glow_color", value)
			_update_particles_color(value)
@export var completed_color: Color = Color(0.5, 0.5, 0.5, 1.0):
	set(value):
		completed_color = value
		if _shader_material and _is_active and !_is_latest_checkpoint:
			_shader_material.set_shader_parameter("glow_color", value)
			_update_particles_color(value)

@export_category("Structure")
@export_range(0.0005, 0.01) var pole_outer_width: float = 0.001:
	set(value):
		pole_outer_width = value
		if _shader_material:
			_shader_material.set_shader_parameter("pole_outer_width", value)
@export_range(0.0005, 0.05) var pole_inner_width: float = 0.001:
	set(value):
		pole_inner_width = value
		if _shader_material:
			_shader_material.set_shader_parameter("pole_inner_width", value)
@export_range(0.3, 0.95) var pole_height: float = 0.745:
	set(value):
		pole_height = value
		if _shader_material:
			_shader_material.set_shader_parameter("pole_height", value)
@export_range(0.1, 0.6) var flag_width: float = 0.33:
	set(value):
		flag_width = value
		if _shader_material:
			_shader_material.set_shader_parameter("flag_width", value)
			_create_particles()
@export_range(0.05, 0.4) var flag_height: float = 0.2:
	set(value):
		flag_height = value
		if _shader_material:
			_shader_material.set_shader_parameter("flag_height", value)
			_create_particles()

@export_category("Visual Effects")
@export_range(0.1, 10.0) var glow_intensity: float = 0.963:
	set(value):
		glow_intensity = value
		if _shader_material:
			_shader_material.set_shader_parameter("glow_intensity", value)
@export_range(0.001, 0.1) var glow_radius: float = 0.006:
	set(value):
		glow_radius = value
		if _shader_material:
			_shader_material.set_shader_parameter("glow_radius", value)
@export_range(0.005, 0.2) var outer_glow_radius: float = 0.059:
	set(value):
		outer_glow_radius = value
		if _shader_material:
			_shader_material.set_shader_parameter("outer_glow_radius", value)
@export_range(0.5, 8.0) var glow_falloff: float = 4.887:
	set(value):
		glow_falloff = value
		if _shader_material:
			_shader_material.set_shader_parameter("glow_falloff", value)
@export_range(0.1, 8.0) var wave_speed: float = 2.0:
	set(value):
		wave_speed = value
		if _shader_material:
			_shader_material.set_shader_parameter("wave_speed", value)
@export_range(0.5, 15.0) var wave_frequency: float = 3.0:
	set(value):
		wave_frequency = value
		if _shader_material:
			_shader_material.set_shader_parameter("wave_frequency", value)
@export_range(0.001, 0.2) var wave_amplitude: float = 0.076:
	set(value):
		wave_amplitude = value
		if _shader_material:
			_shader_material.set_shader_parameter("wave_amplitude", value)
@export_range(0.1, 5.0) var pulse_speed: float = 1.2:
	set(value):
		pulse_speed = value
		if _shader_material:
			_shader_material.set_shader_parameter("pulse_speed", value)
@export_range(0.1, 2.0) var pulse_min: float = 1.299:
	set(value):
		pulse_min = value
		if _shader_material:
			_shader_material.set_shader_parameter("pulse_min", value)
@export_range(1.0, 5.0) var pulse_max: float = 2.049:
	set(value):
		pulse_max = value
		if _shader_material:
			_shader_material.set_shader_parameter("pulse_max", value)

const SHADER_PATH = "res://assets/shaders/checkpoint_flag.gdshader"

var _flag_rect: ColorRect = null
var _particles_top: CPUParticles2D = null
var _particles_bottom: CPUParticles2D = null
var _particles_right: CPUParticles2D = null
var _current_tween: Tween = null
var _is_latest_checkpoint: bool = false
var _is_active: bool = false
var _shader_material: ShaderMaterial = null

var _particle_config = {
	"amount": 8,
	"lifetime": 0.8,
	"randomness": 0.5,
	"emission_shape": CPUParticles2D.EMISSION_SHAPE_POINT,
	"direction": Vector2(1, -0.2),
	"spread": 25.0,
	"gravity": Vector2(0, 5),
	"initial_velocity_min": 15.0,
	"initial_velocity_max": 25.0,
	"scale_amount_min": 1.0,
	"scale_amount_max": 2.0
}

var _flag_state_modifiers = {
	"active": {
		"wave_speed_factor": 1.5,
		"wave_amplitude_factor": 1.2,
		"pulse_min_factor": 1.1,
		"pulse_max_factor": 1.1
	},
	"inactive": {
		"wave_speed_factor": 1.0,
		"wave_amplitude_factor": 1.0,
		"pulse_min_factor": 1.0,
		"pulse_max_factor": 1.0
	},
	"completed": {
		"wave_speed_factor": 0.7,
		"wave_amplitude_factor": 0.5,
		"pulse_min_factor": 0.9,
		"pulse_max_factor": 0.8
	}
}
#endregion


func _init() -> void:
	add_to_group("checkpoints")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_create_flag_rect()
	_setup_flag_shader()
	_create_particles()
	_update_flag_appearance(inactive_color)


func _create_flag_rect() -> void:
	_flag_rect = ColorRect.new()
	_flag_rect.name = "FlagRect"
	_flag_rect.size = Vector2(80, 80)
	_flag_rect.position = Vector2(-15, -60)
	_flag_rect.color = Color(0, 0, 0, 0)
	add_child(_flag_rect)


func _setup_flag_shader() -> void:
	var shader = load(SHADER_PATH)
	if shader:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		
		var shader_params = {
			"glow_color": inactive_color,
			"glow_intensity": glow_intensity,
			"glow_radius": glow_radius,
			"outer_glow_radius": outer_glow_radius,
			"glow_falloff": glow_falloff,
			"pole_outer_width": pole_outer_width,
			"pole_inner_width": pole_inner_width,
			"pole_height": pole_height,
			"flag_width": flag_width,
			"flag_height": flag_height,
			"wave_speed": wave_speed,
			"wave_frequency": wave_frequency,
			"wave_amplitude": wave_amplitude,
			"pulse_speed": pulse_speed,
			"pulse_min": pulse_min,
			"pulse_max": pulse_max
		}
		
		_set_shader_parameters(shader_params)
		_flag_rect.material = _shader_material


func _set_shader_parameters(parameters: Dictionary) -> void:
	if _shader_material:
		for param_name in parameters:
			_shader_material.set_shader_parameter(param_name, parameters[param_name])


func _create_particles() -> void:
	if !_flag_rect:
		return
		
	var flag_top_y = 0.25
	var flag_start_x = 0.15
	
	var top_right_x = (flag_start_x + flag_width) * 80 - 15
	var top_right_y = flag_top_y * 80 - 60
	var bottom_right_y = (flag_top_y + flag_height) * 80 - 60
	
	_cleanup_particles()
	
	_particles_top = _create_particle_emitter(_particle_config, Vector2(top_right_x, top_right_y))
	_particles_bottom = _create_particle_emitter(_particle_config, Vector2(top_right_x, bottom_right_y))
	
	_particles_right = _create_particle_emitter(_particle_config, Vector2(top_right_x, (top_right_y + bottom_right_y) / 2.0))


func _cleanup_particles() -> void:
	for particle in [_particles_top, _particles_bottom, _particles_right]:
		if particle:
			particle.queue_free()


func _create_particle_emitter(config: Dictionary, position: Vector2) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	
	particles.name = config.get("name", "Particles")
	particles.position = position
	particles.amount = config.get("amount", 10)
	particles.lifetime = config.get("lifetime", 1.0)
	particles.randomness = config.get("randomness", 0.5)
	particles.emission_shape = config.get("emission_shape", CPUParticles2D.EMISSION_SHAPE_POINT)
	
	particles.direction = config.get("direction", Vector2(1, 0))
	particles.spread = config.get("spread", 45.0)
	particles.gravity = config.get("gravity", Vector2(0, 0))
	particles.initial_velocity_min = config.get("initial_velocity_min", 10.0)
	particles.initial_velocity_max = config.get("initial_velocity_max", 20.0)
	
	particles.scale_amount_min = config.get("scale_amount_min", 1.0)
	particles.scale_amount_max = config.get("scale_amount_max", 2.0)
	particles.color = inactive_color
	particles.emitting = _is_active
	
	add_child(particles)
	return particles


func _update_particles_color(color: Color) -> void:
	for particle in [_particles_top, _particles_bottom, _particles_right]:
		if particle:
			particle.color = color


func _on_body_entered(body: Node2D) -> void:
	if body is Player and !_is_active:
		_activate()


func _activate() -> void:
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	
	_current_tween = create_tween()
	_current_tween.set_ease(Tween.EASE_OUT)
	_current_tween.set_trans(Tween.TRANS_ELASTIC)
	
	_current_tween.tween_method(
		func(value: float): _shader_material.set_shader_parameter("glow_intensity", value),
		glow_intensity * 3.0,
		glow_intensity,
		0.5
	)
	
	_current_tween.parallel().tween_method(
		_update_flag_appearance, 
		inactive_color,
		active_color, 
		0.5
	)
	
	_update_particles_color(active_color)
	for particle in [_particles_top, _particles_bottom, _particles_right]:
		if particle:
			particle.emitting = true
	
	await _current_tween.finished
	
	_is_active = true
	_is_latest_checkpoint = true
	
	emit_signal("checkpoint_activated", self)


func _update_flag_appearance(color: Color) -> void:
	if !_shader_material:
		return
		
	_shader_material.set_shader_parameter("glow_color", color)
	
	var state_name = "inactive"
	if color == active_color:
		state_name = "active"
	elif color == completed_color:
		state_name = "completed"
	
	var modifiers = _flag_state_modifiers[state_name]
	
	var params = {
		"wave_speed": wave_speed * modifiers.wave_speed_factor,
		"wave_amplitude": wave_amplitude * modifiers.wave_amplitude_factor,
		"pulse_min": pulse_min * modifiers.pulse_min_factor,
		"pulse_max": pulse_max * modifiers.pulse_max_factor
	}
	
	_set_shader_parameters(params)
	_update_particles_color(color)


func set_as_completed() -> void:
	_is_latest_checkpoint = false
	_is_active = true
	
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	
	_current_tween = create_tween()
	
	_current_tween.tween_method(
		_update_flag_appearance, 
		active_color,
		completed_color, 
		0.5
	)
	
	_current_tween.parallel().tween_method(
		func(value: float): _shader_material.set_shader_parameter("glow_intensity", value),
		glow_intensity,
		glow_intensity * 0.7,
		0.5
	)
	
	for particle in [_particles_top, _particles_bottom, _particles_right]:
		if particle:
			_current_tween.tween_property(particle, "emitting", false, 0.2)
