extends Area2D

signal area_level_completed

func _ready() -> void:
	var lm = get_parent().get_node("LevelManager")
	lm.register_level_completed(self)
