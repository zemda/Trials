extends Area2D
class_name DestructiblePlatform

@export_range(1, 100) var platform_length: int = 1
@export_range(0.1, 100.0) var destruction_time: float = 1.5
@export_range(0.1, 100.0) var tile_fall_delay: float = 0.15
@export_range(1, 10000) var fall_distance: float = 150.0
@export_range(0.1, 100.0) var fall_duration: float = 0.5
@export_range(0.0, 100.0) var fade_duration: float = 0.3
@export_range(0.0, 100.0) var initial_shake_intensity: float = 2.0
@export_range(1.0, 100.0) var max_shake_intensity: float = 10.0
@export var warning_particles_color: Color = Color(0.9, 0.6, 0.3, 1.0)
@export var destruction_particles_color: Color = Color(0.7, 0.7, 0.7, 1.0)

var _destruction_started: bool = false
var _tile_instances = []
var start_from_left: bool = true
var _original_position: Vector2
var _shake_intensity: float = 0.0
var _destroyed_tiles_count: int = 0

const SINGLE_TILE_COORDS = Vector2i(3, 0)
const LEFT_EDGE_COORDS = Vector2i(0, 0)
const MIDDLE_TILE_COORDS = Vector2i(1, 0)
const RIGHT_EDGE_COORDS = Vector2i(2, 0)

const TILE_SOURCE_ID = 1


func _init() -> void:
	add_to_group("storable")


func _ready() -> void:
	_create_platform_tiles()
	$CollisionShape2D.scale.x = platform_length
	$CollisionShape2D.position = Vector2(platform_length * 8, -5.0)
	_original_position = position
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if _destruction_started:
		var progress_factor = float(_destroyed_tiles_count) / platform_length
		_shake_intensity = lerp(initial_shake_intensity, max_shake_intensity, progress_factor)
		
		position = _original_position + Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
	else:
		position = _original_position


func _create_platform_tiles() -> void:
	var tile_layer = $base
	
	for i in range(platform_length):
		var coords = Vector2i(i, 0)
		var atlas_coords = _get_atlas_coords_for_index(i)
		
		tile_layer.set_cell(coords, TILE_SOURCE_ID, atlas_coords)
		_tile_instances.append(coords)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and !_destruction_started:
		_destruction_started = true
		
		var platform_center_x = global_position.x + $CollisionShape2D.position.x
		start_from_left = body.global_position.x < platform_center_x
		_shake_intensity = initial_shake_intensity
		
		var first_tile_idx = 0 if start_from_left else platform_length - 1
		var first_coords = _tile_instances[first_tile_idx]
		_create_warning_particles(first_coords)
		
		var timer = get_tree().create_timer(destruction_time)
		timer.timeout.connect(_start_destruction)


func _create_warning_particles(coords: Vector2i) -> void:
	var tile_layer = $base
	var particle_pos = tile_layer.map_to_local(coords)
	particle_pos = tile_layer.to_global(particle_pos)
	
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = 1.0
	particles.one_shot = false
	particles.explosiveness = 0.1
	particles.randomness = 0.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(8, 2)
	particles.direction = Vector2(0, -1)
	particles.gravity = Vector2(0, 40)
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 50
	particles.color = warning_particles_color
	particles.add_to_group("debris")
	
	particles.global_position = particle_pos + Vector2(8, 0)
	get_parent().add_child(particles)
	
	var timer = get_tree().create_timer(destruction_time)
	var particles_ref = weakref(particles)
	timer.timeout.connect(func(): 
		var p = particles_ref.get_ref()
		if p:
			p.queue_free()
	)


func _start_destruction() -> void:
	var tile_layer = $base
	var tile_indexes = range(platform_length)
	
	if not start_from_left:
		tile_indexes.reverse()
	
	for idx in tile_indexes.size():
		var tile_idx = tile_indexes[idx]
		var coords = _tile_instances[tile_idx]
		
		var delay_timer = get_tree().create_timer(idx * tile_fall_delay)
		delay_timer.timeout.connect(func(): _destroy_tile(tile_layer, coords, tile_idx))


func _destroy_tile(tilemap: TileMapLayer, coords: Vector2i, idx: int) -> void:
	var tile_data = tilemap.get_cell_tile_data(coords)
	if not tile_data:
		return
	
	_create_destruction_particles(coords)
	
	var sprite = Sprite2D.new()
	sprite.texture = tilemap.tile_set.get_source(TILE_SOURCE_ID).texture
	
	var atlas_coords = _get_atlas_coords_for_index(idx)
	var tile_size = tilemap.tile_set.get_source(TILE_SOURCE_ID).texture_region_size
	var region = Rect2(atlas_coords.x * tile_size.x, atlas_coords.y * tile_size.y, tile_size.x, tile_size.y)
	
	sprite.region_enabled = true
	sprite.region_rect = region
	
	var tile_position = tilemap.map_to_local(coords)
	sprite.global_position = tilemap.to_global(tile_position)
	sprite.centered = false
	sprite.add_to_group("debris")
	
	tilemap.set_cell(coords, -1)
	get_parent().add_child(sprite)
	
	_destroyed_tiles_count += 1
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(sprite, "position:y", sprite.position.y + fall_distance, fall_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	var rotation_dir = 1 if randf() > 0.5 else -1
	tween.tween_property(sprite, "rotation", rotation_dir * PI/4, fall_duration).set_ease(Tween.EASE_IN)
	
	tween.tween_property(sprite, "modulate:a", 0.0, fade_duration).set_delay(fall_duration - fade_duration)
	var sprite_ref = weakref(sprite)
	tween.tween_callback(func(): 
		var p = sprite_ref.get_ref()
		if p:
			p.queue_free()
	).set_delay(fall_duration)
	
	var remaining_tiles = 0
	for c in _tile_instances:
		if tilemap.get_cell_source_id(c) != -1:
			remaining_tiles += 1
	
	if remaining_tiles == 0:
		_destruction_started = false
		tween.tween_callback(func():
			if is_instance_valid(self):
				queue_free()
		).set_delay(fall_duration)


func _create_destruction_particles(coords: Vector2i) -> void:
	var tile_layer = $base
	var particle_pos = tile_layer.map_to_local(coords)
	particle_pos = tile_layer.to_global(particle_pos)
	
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.7
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(8, 2)
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.gravity = Vector2(0, 100)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 70
	particles.color = destruction_particles_color
	particles.add_to_group("debris")
	
	particles.global_position = particle_pos + Vector2(8, 0)
	get_parent().add_child(particles)
	
	
	var timer = get_tree().create_timer(particles.lifetime * 1.2)
	var particles_ref = weakref(particles)
	timer.timeout.connect(func(): 
		var p = particles_ref.get_ref()
		if p:
			p.queue_free()
	)


func _get_atlas_coords_for_index(idx: int) -> Vector2i:
	if platform_length == 1:
		return SINGLE_TILE_COORDS
	elif idx == 0:
		return LEFT_EDGE_COORDS
	elif idx == platform_length - 1:
		return RIGHT_EDGE_COORDS
	else:
		return MIDDLE_TILE_COORDS
