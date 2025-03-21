extends Area2D

@export var fade_duration: float = 0.4
@export var visible_alpha: float = 1.0
@export var hidden_alpha: float = 0.1

var _ease_type: Tween.EaseType = Tween.EASE_OUT
var _transition_type: Tween.TransitionType = Tween.TRANS_SINE
var _current_tween: Tween = null


func _ready() -> void:
	if get_parent():
		get_parent().modulate.a = visible_alpha


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_cancel_current_tween()
		
		_current_tween = create_tween()
		_current_tween.set_ease(_ease_type)
		_current_tween.set_trans(_transition_type)
		
		var p = get_parent()
		_current_tween.tween_property(p, "modulate:a", hidden_alpha, fade_duration)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_cancel_current_tween()
		
		_current_tween = create_tween()
		_current_tween.set_ease(_ease_type)
		_current_tween.set_trans(_transition_type)
		
		var p = get_parent()
		_current_tween.tween_property(p, "modulate:a", visible_alpha, fade_duration)


func _cancel_current_tween() -> void:
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	_current_tween = null
