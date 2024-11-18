extends Node2D

@onready var tip: CharacterBody2D = $Tip

const SPEED = 30
const HOOK_PULL_SPEED = 400.0

var direction := Vector2.ZERO
var tip_position := Vector2.ZERO

var flying = false
var hooked = false
var player: CharacterBody2D = null


func _process(_delta: float) -> void:
	self.visible = flying or hooked
	if not self.visible:
		return
	
	rotation = (tip_position - global_position).angle()


func _physics_process(_delta: float) -> void:
	if flying:
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
	if hooked:
		tip.global_position = tip_position
		if player:
			var pull_direction = (tip_position - player.global_position).normalized()
			player.velocity = pull_direction * HOOK_PULL_SPEED


func shoot(target_position: Vector2, player_ref: CharacterBody2D) -> void:
	player = player_ref
	direction = (target_position - global_position).normalized()
	
	if direction.angle() > deg_to_rad(45) and direction.angle() < deg_to_rad(135):
		return
	flying = true
	hooked = false
	tip_position = global_position
	tip.global_position = global_position


func release() -> void:
	flying = false
	hooked = false
	player = null
