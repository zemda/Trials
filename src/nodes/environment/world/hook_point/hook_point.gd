extends Area2D
class_name HookPoint

@export var one_time_use_chance: float = 0.5
@export var is_one_time_use: bool = true
@export var x_scale: int = 1

var _current_anchor: Area2D = null
var _marked_for_removal: bool = false


func _init() -> void:
	add_to_group("Hookable")
	if is_one_time_use:
		add_to_group("storable")


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	scale.x = x_scale


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("grapple_anchor"):
		_handle_anchor_entered(area)


func _handle_anchor_entered(anchor: Node2D) -> void:
	_current_anchor = anchor
	if is_one_time_use:
		_marked_for_removal = randf() < one_time_use_chance


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("grapple_anchor") and area == _current_anchor:
		_handle_anchor_exited()


func _handle_anchor_exited() -> void:
	if _marked_for_removal:
		queue_free()
	
	_current_anchor = null
	_marked_for_removal = false
