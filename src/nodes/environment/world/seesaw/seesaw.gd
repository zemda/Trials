extends MasterChain

@export var plank_scene: PackedScene


func _ready() -> void:
	create_chain()
	
	var _hook = segments.back()
	var _hook_position = _hook.global_position

	var _plank = plank_scene.instantiate()
	add_child(_plank)
	_plank.global_position = _hook_position + Vector2(0, 11)
	
	_plank.attach_to_chain(_hook)
