extends Area2D


@export_category("Teleport Settings")
@export var correct_chance: float = 0.75
@export var fade_time: float = 0.5

@export_category("Visual Settings")
@export_range(0.5, 10.0) var scale_factor: float = 1.0
@export var portal_color: Color = Color(0.5, 0.2, 1.0, 1.0)
@export var color_good: Color = Color(0.3, 1.0, 0.3, 1.0)
@export var color_bad: Color = Color(1.0, 0.3, 0.3, 1.0)
@export_range(1.0, 10.0) var electric_intensity: float = 1.0

var _is_teleporting: bool = false

const SHADER_PATH_ELECTRIC = "res://assets/shaders/electric_ring.gdshader"
const SHADER_PATH_GLOW = "res://assets/shaders/background_glow.gdshader"
const SHADER_PATH_BALL = "res://assets/shaders/center_ball.gdshader"

var _teleport_cooldown: float = 5.0
var _teleport_cooldown_timer: float = 0.0
var _last_teleported_player = null
var correct_destination: Vector2 = Vector2.ZERO
var fallback_destination: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_create_portal()
	
	correct_destination = $HappyPath.global_position
	fallback_destination = $SadPath.global_position


func _process(delta: float) -> void:
	var ring = get_node_or_null("ElectricRing")
	if ring and ring.material:
		ring.material.set_shader_parameter("time_scale", 1.0 + 0.2 * sin(Time.get_ticks_msec() / 1000.0))
	
	if _teleport_cooldown_timer > 0:
		_teleport_cooldown_timer -= delta


func _create_portal() -> void:
	_clear_visuals()
	_add_background_glow(portal_color)
	_add_electric_ring(portal_color)
	_add_center_ball(portal_color)
	_add_particles(portal_color)



func _on_body_entered(body: Node2D) -> void:
	if _teleport_cooldown_timer < 0:
		_teleport_cooldown_timer = _teleport_cooldown
	if _is_teleporting or _teleport_cooldown_timer > 0:
		return
	if body is Player:
		_is_teleporting = true
		GameManager.disable_player_input()
		_process_teleport(body)


func _process_teleport(player: Player) -> void:
	var go_to_correct = randf() < correct_chance
	var target_pos = correct_destination if go_to_correct else fallback_destination
	
	var dest_circle = _create_teleport_circle(target_pos, go_to_correct)
	dest_circle.scale = Vector2(0.2, 0.2)
	
	var tween = create_tween()
	
	var portal_center_y = global_position.y
	tween.tween_property(player, "global_position:y", portal_center_y, 0.3)
	
	tween.parallel().tween_property(dest_circle, "scale", Vector2(1.0, 1.0), fade_time * 0.3)
	
	tween.tween_callback(func():
		player.global_position = target_pos
		GameManager.enable_player_input()
	)
	
	tween.tween_property(dest_circle, "scale", Vector2(0.0, 0.0), fade_time * 0.4)
	
	tween.tween_callback(func():
		dest_circle.queue_free()
		_is_teleporting = false
	)


func _create_teleport_circle(pos: Vector2, is_good: bool) -> Node2D:
	var circle_node = Node2D.new()
	circle_node.global_position = pos
	get_tree().root.add_child(circle_node)
	
	var color = color_good if is_good else color_bad
	
	var ring = _create_electric_ring(color)
	circle_node.add_child(ring)
	
	var particles = _create_particles(color)
	circle_node.add_child(particles)
	
	return circle_node


func _clear_visuals() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			continue
		child.queue_free()


func _add_background_glow(color: Color) -> void:
	var glow = _create_background_glow(color)
	add_child(glow)


func _add_electric_ring(color: Color) -> void:
	var ring = _create_electric_ring(color)
	add_child(ring)


func _add_center_ball(color: Color) -> void:
	var ball = _create_center_ball(color)
	add_child(ball)


func _add_particles(color: Color) -> void:
	var particles = _create_particles(color)
	add_child(particles)


func _create_background_glow(color: Color) -> ColorRect:
	var glow = ColorRect.new()
	glow.name = "GlowEffect"
	var glow_size = 180 * scale_factor
	glow.size = Vector2(glow_size, glow_size)
	glow.position = Vector2(-glow_size/2, -glow_size/2)
	glow.color = color
	glow.z_index = -1
	
	var glow_shader = load(SHADER_PATH_GLOW)
	if glow_shader:
		var glow_material = ShaderMaterial.new()
		glow_material.shader = glow_shader
		glow_material.set_shader_parameter("color", color)
		glow_material.set_shader_parameter("glow_radius", 0.5)
		glow_material.set_shader_parameter("glow_intensity", 0.5)
		glow.material = glow_material
	return glow


func _create_electric_ring(color: Color) -> ColorRect:
	var ring = ColorRect.new()
	ring.name = "ElectricRing"
	var size = 120 * scale_factor
	ring.size = Vector2(size, size)
	ring.position = Vector2(-size/2, -size/2)
	ring.color = color
	ring.z_index = 0
	
	var noise_tex = _create_noise_texture(FastNoiseLite.TYPE_VALUE_CUBIC, 256, 0.05)
	var noise_tex2 = _create_noise_texture(FastNoiseLite.TYPE_VALUE_CUBIC, 256, 0.1)
	
	var electric_shader = load(SHADER_PATH_ELECTRIC)
	if electric_shader:
		var ring_material = ShaderMaterial.new()
		ring_material.shader = electric_shader
		ring_material.set_shader_parameter("noise", noise_tex)
		ring_material.set_shader_parameter("noise2", noise_tex2)
		ring_material.set_shader_parameter("brightness", 5.0)
		ring_material.set_shader_parameter("time_scale", 1.0)
		ring.material = ring_material
	return ring


func _create_center_ball(color: Color) -> ColorRect:
	var ball = ColorRect.new()
	ball.name = "ElectricBall"
	var ball_size = 60 * scale_factor
	ball.size = Vector2(ball_size, ball_size)
	ball.position = Vector2(-ball_size/2, -ball_size/2)
	ball.color = color.lightened(0.3)
	ball.z_index = 1
	
	var ball_shader = load(SHADER_PATH_BALL)
	if ball_shader:
		var ball_material = ShaderMaterial.new()
		ball_material.shader = ball_shader
		ball_material.set_shader_parameter("color", color.lightened(0.3))
		ball_material.set_shader_parameter("pulse_speed", 2.0)
		ball.material = ball_material
	return ball


func _create_particles(color: Color) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.name = "PortalParticles"
	particles.amount = 30
	particles.lifetime = 1.5
	particles.emitting = true
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 40.0 * scale_factor
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.gravity = Vector2(0, -10)
	particles.initial_velocity_min = 5
	particles.initial_velocity_max = 15
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.modulate = color
	particles.z_index = 2
	
	return particles


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
