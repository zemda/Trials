extends Node

var _loading_screen = null
var _is_visible = false
var _current_progress = 0.0

const LoadingScreenPath = "res://ui/loading_screen/LoadingScreen.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_loading_screen()


func _create_loading_screen() -> void:
	if _loading_screen:
		return
	
	var scene = load(LoadingScreenPath)
	_loading_screen = scene.instantiate()
	_loading_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	_loading_screen.add_to_group("loading_screen")
	
	get_tree().root.call_deferred("add_child", _loading_screen)
	call_deferred("_ensure_hidden")


func _ensure_hidden() -> void:
	if _loading_screen:
		_loading_screen.visible = false


func show_loading_screen() -> void:
	if _is_visible:
		return
	_is_visible = true
	_loading_screen.show_loading_screen()
	update_progress(0.0)


func hide_loading_screen() -> void:
	if not _is_visible:
		return
	_is_visible = false
	_loading_screen.hide_loading_screen()


func update_progress(value: float) -> void:
	_current_progress = value
	
	if _loading_screen and _is_visible:
		_loading_screen.update_progress(value)


func is_visible() -> bool:
	return _is_visible


func get_current_progress() -> float:
	return _current_progress
