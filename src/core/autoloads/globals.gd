extends Node


func _ready() -> void:
	var mouse_arrow = preload("res://assets/cursor/4.png")
	Input.set_custom_mouse_cursor(mouse_arrow, Input.CURSOR_ARROW)
