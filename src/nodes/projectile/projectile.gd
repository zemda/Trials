extends CharacterBody2D


@export var projectile_speed: float = 2000.0
@export var knockback_force: float = 20.0
@export var arc: float = 10.0

var is_shooter_on_ceiling: bool = false
var shooter_position: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	velocity.y += projectile_speed * delta
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		if collider is Player:
			var base_direction = (collider.global_position - shooter_position).normalized()
			var knockback_direction = base_direction
			
			var hitting_from_above = global_position.y < collider.global_position.y
			
			if hitting_from_above:
				knockback_direction = Vector2(base_direction.x, 0.0).normalized()
			else:
				knockback_direction = Vector2(base_direction.x, -0.8).normalized()
			
			collider.knockback(knockback_direction, knockback_force)
			
		destroy()


func launch(target_position: Vector2, shooter_pos: Vector2) -> void:
	var arc_ = arc if not is_shooter_on_ceiling else 1
	var arc_height = target_position.y - global_position.y - arc_
	shooter_position = shooter_pos
	arc_height = min(-arc_, arc_height)
	velocity = _get_arc_velocity(global_position, target_position, arc_height, projectile_speed, projectile_speed)
	$Area2D.monitoring = true


func destroy() -> void:
	queue_free()


func _get_arc_velocity(point_a: Vector2, point_b: Vector2, arc_height: float, up_gravity: float, down_gravity: float) -> Vector2:
	
	var _velocity := Vector2.ZERO
	var displacement = point_b - point_a
	
	if displacement.y > arc_height:
		var time_up = sqrt(-2 * arc_height / float(up_gravity))
		var time_down = sqrt(2 * (displacement.y - arc_height) / float(down_gravity))
		
		_velocity.y = -sqrt(-2 * up_gravity * arc_height)
		_velocity.x = displacement.x / float(time_up + time_down)
	
	return _velocity
