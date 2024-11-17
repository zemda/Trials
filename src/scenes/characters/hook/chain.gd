extends Node2D

@onready var links = $Links
@onready var tip: CharacterBody2D = $Tip

const SPEED = 25

var direction := Vector2.ZERO
var tip_position := Vector2.ZERO

var flying = false
var hooked = false

func _process(_delta: float) -> void:
	self.visible = flying or hooked
	if not self.visible:
		return
	
	
	rotation = (tip_position - global_position).angle()
	var tip_loc = to_local(tip_position)
	var distance = tip_loc.length()
	links.region_rect.size.y = round(distance / 5.6) * 16


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
	


func shoot(target_position) -> void:
	direction = (target_position - global_position).normalized()
	if direction.angle() > deg_to_rad(45) and direction.angle() < deg_to_rad(135):
		return
	flying = true
	tip_position = global_position
	tip.global_position = tip_position


func release() -> void:
	flying = false
	hooked = false
