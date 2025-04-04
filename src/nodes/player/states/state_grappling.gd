extends FSMState

func _enter() -> void:
	_switch_collisions()


func update(_delta: float) -> void:
	host.update_animations(0)
	host.handle_downward_cast()


func _exit() -> void:
	_switch_collisions()


func _transition() -> int:
	if not host.get_node("GrapplingHook").hooked:
		if host.is_on_floor():
			return states.IDLE
		else:
			return states.JUMP
	elif host.is_attached_to_rope:
		return states.SWINGING
	else:
		return states.NONE


func _switch_collisions() -> void:
	host.velocity.y += -2
	
	var coll = host.find_child("CollisionShape2D")
	coll.set_deferred("disabled", !coll.is_disabled())
	
	var grapp_coll = host.find_child("grappleCollision")
	grapp_coll.set_deferred("disabled", !grapp_coll.is_disabled())
	
