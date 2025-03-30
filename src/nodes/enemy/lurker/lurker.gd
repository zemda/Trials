extends Enemy
class_name LurkingEnemy

@export var can_stop_lurking: bool = false

var _original_ceiling_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	_original_ceiling_position = global_position


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if velocity != Vector2.ZERO:
		$Sprite2D.play("run")  
	else: 
		$Sprite2D.play("idle")
