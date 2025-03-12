extends Node2D

signal hit_hookable(position, collider)
signal failed

@export var speed := 800.0
var _direction := Vector2.ZERO
var _max_distance := 500.0
var _distance_traveled := 0.0
var _target_position := Vector2.ZERO
var _is_hooked := false
var _is_fading := false

@onready var sprite := $Sprite2D # TODO: better sprite img


func _ready() -> void:
	set_process(false)
	add_to_group("grapple_anchor")


func shoot(start_pos: Vector2, target_pos: Vector2) -> void:
	global_position = start_pos
	_target_position = target_pos
	_direction = (target_pos - start_pos).normalized()
	_distance_traveled = 0.0
	_is_hooked = false
	_is_fading = false
	set_process(true)
	visible = true
	
	var tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2(3.0, 3.0), 0.4).from(Vector2(1.0, 1.0))


func _process(delta: float) -> void:
	if _is_hooked or _is_fading:
		return
		
	var velocity = _direction * speed * delta
	global_position += velocity
	_distance_traveled += velocity.length()
	
	if _distance_traveled >= _max_distance:
		_on_failed()
		return
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position - _direction * 5, 
		global_position + _direction * 10
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		global_position = result.position
		set_process(false)
		
		if result.collider.is_in_group("Hookable"):
			_is_hooked = true
			hit_hookable.emit(result.position, result.collider)
		else:
			_on_failed()


func _on_failed() -> void:
	if _is_fading:
		return
		
	_is_fading = true
	set_process(false)
	
	var tween = create_tween().set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(func(): 
		failed.emit()
		queue_free()
	)
