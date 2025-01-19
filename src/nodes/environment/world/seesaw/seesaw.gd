extends Node2D

@export var chain_scene: PackedScene
@export var plank_scene: PackedScene
@export var segment_count: int = 5


func _ready() -> void:
	var _chain = chain_scene.instantiate()
	_chain.segment_count = segment_count
	add_child(_chain)
	
	var _hook = _chain.get_node("Hook")
	var _hook_position = _hook.global_position

	var _plank = plank_scene.instantiate()
	add_child(_plank)
	_plank.global_position = _hook_position + Vector2(0, 11)
	
	_plank.attach_to_chain(_hook)
