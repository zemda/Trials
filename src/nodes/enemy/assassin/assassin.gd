extends Enemy

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if velocity != Vector2.ZERO:
		$Sprite2D.play("run")  
	else: 
		$Sprite2D.play("idle")
