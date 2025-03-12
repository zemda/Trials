extends Node2D

signal hook_created(anchor)
signal hook_destroyed

var hooked := false
var _parent: CharacterBody2D
var _current_anchor = null
var _hook_position := Vector2.ZERO
var _hook_collider = null
var _valid_hook_point := false

@onready var fsm = $States
@onready var hook_target_ray: RayCast2D = $TargetRay
@export var anchor_scene: PackedScene

func _ready() -> void:
	fsm.set_host(self)
	_parent = get_parent()


func apply_grapple_physics(center: Vector2, delta: float) -> void:
	const DESIRED_RADIAL_SPEED = 400
	const RADIAL_ACCEL_FACTOR = 0.9
	const INITIAL_SWING_SPEED = 100
	const SWING_FORCE_MULTIPLIER = 70
	const MAX_VELOCITY = Vector2(200, 200)

	var to_center = center - _parent.global_position
	var distance = to_center.length()
	if distance < 1: # TODO: do this smarter, since this doesnt account players size, corners, and so on... 
		_parent.velocity = Vector2.ZERO
		return

	var dir = to_center / distance
	var radial_vel = _parent.velocity.dot(dir)
	var tangential_vel = _parent.velocity - dir * radial_vel

	if tangential_vel == Vector2.ZERO:
		tangential_vel = Vector2(dir.x, -dir.y) * INITIAL_SWING_SPEED

	tangential_vel += Vector2(dir.x, -dir.y) * Input.get_axis("move_left", "move_right") * SWING_FORCE_MULTIPLIER * delta
	var radial_accel = (DESIRED_RADIAL_SPEED - radial_vel) * RADIAL_ACCEL_FACTOR * delta
	_parent.velocity = dir * radial_vel + tangential_vel + dir * radial_accel
	_parent.velocity = _parent.velocity.clamp(-MAX_VELOCITY,MAX_VELOCITY)
	_parent.move_and_slide()


func create_hook(start_pos: Vector2, target_pos: Vector2) -> void:	
	_valid_hook_point = false
	_current_anchor = anchor_scene.instantiate()
	
	var root_node = get_tree().get_root()
	root_node.add_child(_current_anchor)
	
	var aim_direction = (target_pos - start_pos).normalized()
	hook_target_ray.target_position = aim_direction * 500
	hook_target_ray.force_raycast_update()
	
	var final_target_pos
	if hook_target_ray.is_colliding():
		final_target_pos = hook_target_ray.get_collision_point()
	else:
		final_target_pos = start_pos + aim_direction * 500
	
	_current_anchor.hit_hookable.connect(_on_hit_hookable)
	_current_anchor.failed.connect(_on_hook_failed)
	
	_current_anchor.shoot(start_pos, final_target_pos)
	hook_created.emit(_current_anchor)


func _on_hit_hookable(position: Vector2, collider: Node2D) -> void:
	_valid_hook_point = true
	_hook_position = position
	_hook_collider = collider


func _on_hook_failed() -> void:
	_current_anchor = null
	_valid_hook_point = false


func cleanup_current_hook() -> void:
	if _current_anchor:
		if is_instance_valid(_current_anchor):
			if _current_anchor.is_connected("hit_hookable", _on_hit_hookable):
				_current_anchor.disconnect("hit_hookable", _on_hit_hookable)
			if _current_anchor.is_connected("failed", _on_hook_failed):
				_current_anchor.disconnect("failed", _on_hook_failed)
			
			_current_anchor.queue_free()
		
		_current_anchor = null
		hook_destroyed.emit()


func is_hook_valid() -> bool:
	return _valid_hook_point and is_instance_valid(_current_anchor)


func get_hook_data() -> Dictionary:
	return {
		"position": _hook_position,
		"collider": _hook_collider,
		"anchor": _current_anchor
	}


func reset_hook_validity() -> void:
	_valid_hook_point = false
