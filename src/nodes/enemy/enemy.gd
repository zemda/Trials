extends CharacterBody2D
class_name Enemy

const NO_TARGET: Vector2 = Vector2(-9999999, -9999999)

var _current_path: Array = []
var _current_target: Vector2 = NO_TARGET
var _go_to_position: Vector2 = NO_TARGET

@export var _speed: float = 160.0
@export var _jump_force: float = 375.0

@export var max_jump_height: int = 4
@export var max_jump_distance: int = 8

@export var player_height: int = 1
@export var player_width: int = 1

var _padding: float = 2.5
var _finish_padding: float = 5.0
var _stuck_timer: float = 0.0
var _stuck_timeout: float = 0.5

var path_finder: Pathfinder
@export var debug_draw: bool = true


func init_pathfinder(finder: Pathfinder) -> void:
	path_finder = finder


func _physics_process(delta: float) -> void:
	_handle_input()
	if Input.is_action_just_pressed("ui_cancel"):
		_clear_path()
		return
	
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
	else:
		velocity.x = 0
		if _go_to_position != NO_TARGET:
			if abs(_go_to_position.x - position.x) > _finish_padding * 2:
				print("Velocity 0..., ", position.distance_to(_go_to_position), ", pos: ", position, "go to: ", _go_to_position)
				_recalculate_path()
			else:
				_go_to_position = NO_TARGET

	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
	if debug_draw:
		queue_redraw()


func _move_towards_target() -> void:
	if _current_target == NO_TARGET:
		velocity.x = 0
		return
	
	if (_current_target.x - _padding > position.x):
		velocity.x = _speed
	elif (_current_target.x + _padding < position.x):
		velocity.x = -_speed
	else:
		#print("m: ", abs(_current_target.x - position.x), ", dist to: ", position.distance_to(_current_target))
		velocity.x = 0
	
	if position.distance_to(_current_target) < _finish_padding and is_on_floor():
		_next_point()
		_stuck_timer = 0


func _next_point() -> void:
	if _current_path.size() == 0:
		_current_target = NO_TARGET
		return
	
	var next_node = _current_path.pop_front()
	
	if next_node == null:
		_current_target = NO_TARGET
		return
		
	if next_node.get("type", "move") == "jump":
		if is_on_floor():
			var height = next_node.get("height", 1)
			var distance = next_node.get("distance", 1)
			var jump_force = next_node.get("jump_force", 380)

			print("Jump with: ", jump_force, ", distance: ", distance, ", height: ", height)
			velocity.y = -jump_force
	
	_current_target = next_node.position


func _check_if_stuck(delta: float) -> void:
	if _current_path.size() >= 0 and abs(velocity.x) < 10.0 and is_on_floor():
		_stuck_timer += delta
		if _stuck_timer > _stuck_timeout:
			print("Stuck...")
			_recalculate_path()
			_stuck_timer = 0
	else:
		_stuck_timer = 0


func _clear_path() -> void:
	_current_target = NO_TARGET
	_current_path.clear()
	_go_to_position = NO_TARGET
	velocity = Vector2.ZERO
	_stuck_timer = 0


func _recalculate_path() -> void:
	print("Recalculating...")
	if _go_to_position != NO_TARGET and path_finder:
		var new_path = path_finder.find_path(
			global_position,
			_go_to_position,
			player_width,
			player_height
		)
		
		if new_path.size() > 0:
			_current_path = new_path
			_next_point()
		else:
			_clear_path()


func move_to(destination: Vector2) -> void:
	_go_to_position = destination
	_current_path.clear()
	_current_target = NO_TARGET
	_stuck_timer = 0
	
	if path_finder:
		var new_path = path_finder.find_path(
			global_position,
			destination,
			player_width,
			player_height
		)

		if new_path.size() > 0:
			_current_path = new_path
			_next_point()
		else:
			_go_to_position = NO_TARGET


func _draw() -> void:
	if not debug_draw:
		return
	
	# Draw path
	var last_pos = global_position
	for node in _current_path:
		var node_pos = node.position
		var color = Color.GRAY
		if node.get("type", "move") == "jump":
			color = Color.RED
		
		draw_line(last_pos - global_position, node_pos - global_position, color, 2.0)
		draw_circle(node_pos - global_position, 3.0, color)
		last_pos = node_pos


func _handle_input() -> void:
	if Input.is_action_just_pressed("grapple"):
		var click_pos = get_global_mouse_position()
		move_to(click_pos)






#extends CharacterBody2D
#
#@export var enemy_settings: Resource
#
#@onready var fsm: FSM = $FSM
#
#
#func _ready() -> void:
	#fsm.set_host(self)
	#
	#if enemy_settings == null:
		#enemy_settings = preload("res://resources/enemy/DefaultEnemy.tres")
	#else:
		#var sprite = $Sprite2D
		#if sprite:
			#print("enemy: ", enemy_settings.display_color)
			#sprite.modulate = enemy_settings.display_color
#
#
#func apply_gravity(delta: float) -> void:
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
#
#func is_player_in_range() -> bool:
	#return false
