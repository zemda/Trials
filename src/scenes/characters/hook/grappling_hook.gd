extends Node2D

@onready var tip: CharacterBody2D = $Tip
@onready var rope: Line2D = $Rope
@onready var raycast: RayCast2D = $RayCast2D

const SPEED = 30
const MAX_DISTANCE = 500

var direction := Vector2.ZERO
var tip_position := Vector2.ZERO

var flying = false
var hooked = false


func _ready():
	rope.width = 3
	rope.default_color = Color(1, 1, 1)
	rope.visible = false
	tip.visible = false


func _process(delta: float) -> void:
	if not flying and not hooked:
		release()
		return

	rope.visible = true
	tip.visible = true

	var player_pos = get_parent().global_position - global_position
	var tip_pos = tip.global_position - global_position
	rope.points = [player_pos, tip_pos]


func _physics_process(delta: float) -> void:
	if flying:
		handle_flying()
	if hooked:
		tip.global_position = tip_position


func shoot(target_position: Vector2) -> void:
	var player_pos = get_parent().global_position
	var distance = player_pos.distance_to(target_position)

	if distance > MAX_DISTANCE:
		return
	
	direction = (target_position - global_position).normalized()
	raycast.target_position = direction * MAX_DISTANCE
	raycast.force_raycast_update()
	if not raycast.is_colliding() or not raycast.get_collider().is_in_group("Hookable"):
		return

	if direction.angle() > deg_to_rad(45) and direction.angle() < deg_to_rad(135):
		return
	
	flying = true
	hooked = false
	tip_position = global_position
	tip.global_position = global_position
	tip.visible = true
	rope.visible = true
	rope.points = []


func handle_flying():
	var collision = tip.move_and_collide(direction * SPEED)
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("Hookable"):
			hooked = true
			flying = false
			tip_position = collision.get_position()
			tip.global_position = tip_position
		else:
			flying = false
			release()
	else:
		raycast.target_position = direction * MAX_DISTANCE
		raycast.force_raycast_update()
		if not raycast.is_colliding() or not raycast.get_collider().is_in_group("Hookable"):
			release()


func release() -> void:
	flying = false
	hooked = false
	tip_position = Vector2.ZERO
	tip.visible = false
	rope.visible = false
	rope.points = []
