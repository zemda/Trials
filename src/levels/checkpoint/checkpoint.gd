extends Area2D
class_name Checkpoint

signal checkpoint_activated(checkpoint)

@export var is_active: bool = false
@export var checkpoint_id: String = ""
@export var light_color: Color = Color(0, 1, 0, 1)  # Green when active
@export var inactive_color: Color = Color(1, 0, 0, 1)  # Red when inactive
@export var completed_color: Color = Color(0.5, 0.5, 0.5, 1)  # Gray for passed checkpoints
@export var pulse_speed: float = 1.0
@export var pulse_intensity: float = 0.3

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var _current_tween: Tween = null
var _is_latest_checkpoint: bool = false


func _init() -> void:
	add_to_group("checkpoints")


func _ready() -> void:
	if !is_active:
		modulate = inactive_color
	else:
		modulate = light_color
		_is_latest_checkpoint = true
		GameManager.current_checkpoint = self.get_path()
		_start_active_animation()
	
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("Player") and !is_active:
		_activate()


func _activate():
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	
	_current_tween = create_tween()
	_current_tween.set_ease(Tween.EASE_OUT)
	_current_tween.set_trans(Tween.TRANS_ELASTIC)
	
	_current_tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.3)
	
	_current_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	_current_tween.tween_property(self, "modulate", light_color, 0.5)
	
	_current_tween.parallel().tween_property(sprite, "scale", Vector2(1, 1), 0.5)
	
	await _current_tween.finished
	
	is_active = true
	_is_latest_checkpoint = true
	
	_start_active_animation()
	emit_signal("checkpoint_activated", self)


func _start_active_animation():
	_current_tween = create_tween()
	_current_tween.set_loops()
	_current_tween.bind_node(self)
	
	var dim_color = light_color.darkened(pulse_intensity)
	var bright_color = light_color.lightened(pulse_intensity)
	
	_current_tween.tween_property(self, "modulate", bright_color, 1.0 / pulse_speed)
	_current_tween.tween_property(self, "modulate", dim_color, 1.0 / pulse_speed)


func set_as_completed():
	_is_latest_checkpoint = false
	is_active = true
	
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
	
	_current_tween = create_tween()
	_current_tween.tween_property(self, "modulate", completed_color, 0.5)
