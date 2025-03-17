extends FSMState

@export var _anchor_scene: PackedScene

var _is_button_held := false
var _was_button_held := false


func _enter() -> void:
	host.reset_hook_validity()


func update(_delta: float) -> void:
	_was_button_held = _is_button_held
	_is_button_held = Input.is_action_pressed("grapple")
	
	if _is_button_held and host.get_parent().can_grapple():
		if not _was_button_held:
			_shoot_grapple()
	else:
		if _was_button_held:
			if not host.is_hook_valid():
				host.cleanup_current_hook()


func _transition() -> int:
	if host.is_hook_valid() and host.get_parent().can_grapple():
		return states.GRAPPLE
	return states.NONE


func _shoot_grapple() -> void:
	var start_pos = host.global_position
	var target_pos = host.get_parent().get_global_mouse_position()
	host.create_hook(start_pos, target_pos)
