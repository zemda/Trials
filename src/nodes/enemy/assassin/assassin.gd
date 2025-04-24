extends Enemy
class_name Assasin

@export var should_wander: bool = true
@onready var explo_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if velocity != Vector2.ZERO:
		$Sprite2D.play("run")  
	else: 
		$Sprite2D.play("idle")
