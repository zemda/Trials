extends ColorRect


@export_group("Background Settings")
@export var bg_parallax_strength: float = -1.0:
	set(value):
		bg_parallax_strength = value
		if material:
			material.set_shader_parameter("parallax_strength", value)

@export var bg_time_scale: float = 0.3:
	set(value):
		bg_time_scale = value
		if material:
			material.set_shader_parameter("time_scale", value)

@export_range(1.0, 5000.0) var scale_factor: float = 600.0:
	set(value):
		scale_factor = value
		if material:
			material.set_shader_parameter("scale_factor", value)

@export_group("Star Settings")
@export_range(0.0, 1.0) var star_density: float = 0.05:
	set(value):
		star_density = value
		if material:
			material.set_shader_parameter("star_density", value)

@export_range(0.0, 5.0) var star_twinkle_speed: float = 3.675:
	set(value):
		star_twinkle_speed = value
		if material:
			material.set_shader_parameter("star_twinkle_speed", value)

@export var star_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		star_color = value
		if material:
			material.set_shader_parameter("star_color", value)

@export_group("Aurora Settings")
@export var aurora_enabled: bool = false:
	set(value):
		aurora_enabled = value
		if material:
			var intensity = aurora_intensity if value else 0.0
			material.set_shader_parameter("aurora_intensity", intensity)

@export_range(0.0, 1.0) var aurora_intensity: float = 0.288:
	set(value):
		aurora_intensity = value
		if material:
			var intensity = value if aurora_enabled else 0.0
			material.set_shader_parameter("aurora_intensity", intensity)

@export_range(0.0, 5.0) var aurora_speed: float = 2.0:
	set(value):
		aurora_speed = value
		if material:
			material.set_shader_parameter("aurora_speed", value)

@export var aurora_color1: Color = Color(0.1, 0.5, 0.8, 1.0):
	set(value):
		aurora_color1 = value
		if material:
			material.set_shader_parameter("aurora_color1", value)

@export var aurora_color2: Color = Color(0.1, 0.8, 0.4, 1.0):
	set(value):
		aurora_color2 = value
		if material:
			material.set_shader_parameter("aurora_color2", value)

@export_range(0.0, 3.0) var aurora_frequency: float = 0.379:
	set(value):
		aurora_frequency = value
		if material:
			material.set_shader_parameter("aurora_frequency", value)

@export_group("Milky Way Settings")
@export var milkyway_enabled: bool = true:
	set(value):
		milkyway_enabled = value
		if material:
			var intensity = milkyway_intensity if value else 0.0
			material.set_shader_parameter("milkyway_intensity", intensity)

@export_range(0.0, 2.0) var milkyway_intensity: float = 1.0:
	set(value):
		milkyway_intensity = value
		if material:
			var intensity = value if milkyway_enabled else 0.0
			material.set_shader_parameter("milkyway_intensity", intensity)

@export_range(0.1, 10.0) var milkyway_scale_factor: float = 1.675:
	set(value):
		milkyway_scale_factor = value
		if material:
			material.set_shader_parameter("milkyway_scale_factor", value)

@export var milkyway_color: Color = Color(0.5, 0.5, 0.8, 0.2):
	set(value):
		milkyway_color = value
		if material:
			material.set_shader_parameter("milkyway_color", value)

@export_group("Shooting Star Settings")
@export var shooting_stars_enabled: bool = true:
	set(value):
		shooting_stars_enabled = value
		if material:
			var chance = shooting_star_chance if value else 0.0
			material.set_shader_parameter("shooting_star_chance", chance)

@export_range(0.0, 1.0) var shooting_star_chance: float = 1.0:
	set(value):
		shooting_star_chance = value
		if material:
			var chance = value if shooting_stars_enabled else 0.0
			material.set_shader_parameter("shooting_star_chance", chance)

@export_range(0.5, 10.0) var shooting_star_speed: float = 1.31:
	set(value):
		shooting_star_speed = value
		if material:
			material.set_shader_parameter("shooting_star_speed", value)
