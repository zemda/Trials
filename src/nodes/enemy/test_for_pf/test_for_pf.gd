extends Enemy

@export var white_sprite: bool = true


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if white_sprite:
		if velocity != Vector2.ZERO:
			$Sprite2D.play("run1")  
		else: 
			$Sprite2D.play("idle1")
		
	else:
		if velocity != Vector2.ZERO:
			$Sprite2D.play("run2")
		else:
			$Sprite2D.play("idle2")
	
