extends CharacterBody2D

const NO_TARGET: Vector2 = Vector2(-9999999, -9999999)

var _current_path: Array = []
var _current_target: Vector2 = NO_TARGET
var _path_finder: Node
var _go_to_position: Vector2 = NO_TARGET
var _speed: float = 100
var _jump_force: float = 200 # TODO: let him jump as high as player, adjust pathfinding distance and height... its up to 8-10 tiles
var _gravity: float = 550
var _padding: float = 1
var _finish_padding: float = 5
var _stuck_timer: float = 0
var _stuck_timeout: float = 0.1


func _ready():
	var map_parent = find_parent("TestMainMap")
	if map_parent:
		_path_finder = map_parent.get_node("Pathfinder")


func _physics_process(delta: float) -> void:
	_handle_input()
	
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
	else:
		velocity.x = 0
		if _go_to_position != NO_TARGET:
			if position.distance_to(_go_to_position) > _finish_padding * 2:
				print("Path finished but destination not reached, recalculating")
				_recalculate_path()
			else:
				_go_to_position = NO_TARGET
	
	_apply_gravity(delta)
	move_and_slide()


func _next_point() -> void:
	if len(_current_path) == 0:
		_current_target = NO_TARGET
		return
	
	var next_point = _current_path.pop_front()
	
	if next_point == null:
		_jump()
		_next_point()
	else:
		_current_target = next_point


func _recalculate_path() -> void:
	if _go_to_position != NO_TARGET and _path_finder:
		print("Recalculating path...")
		
		var new_path = _path_finder.find_path(position, _go_to_position)
		
		if len(new_path) > 0:
			_current_path = new_path
			_next_point()
			return
		else:
			print("No path after retry")
			_current_target = NO_TARGET
			_go_to_position = NO_TARGET
			return
	else:
		print("Recalculate failed")
		return


func _set_path(destination: Vector2) -> void:
	_go_to_position = destination
	_current_path = _path_finder.find_path(position, _go_to_position)
	if not _current_path or len(_current_path) == 0:
		_go_to_position = NO_TARGET
		return
	else:
		_next_point()
		return


func _jump() -> void:
	if is_on_floor():
		velocity.y = -_jump_force


func _move_towards_target() -> void:
	if _current_target == NO_TARGET:
		return
		
	if (_current_target.x - _padding > position.x):
		velocity.x = _speed
	elif (_current_target.x + _padding < position.x):
		velocity.x = -_speed
	else:
		velocity.x = 0
		
	if position.distance_to(_current_target) < _finish_padding and is_on_floor():
		_next_point()
		_stuck_timer = 0


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta


func _check_if_stuck(delta: float) -> void:
	if len(_current_path) and not abs(velocity) > Vector2.ZERO:
		_stuck_timer += delta
		if _stuck_timer > _stuck_timeout:
			print("Stuck for too long, recalculating path, path len: ", len(_current_path))
			_stuck_timer = 0
			_recalculate_path()
	else:
		_stuck_timer = 0


func _handle_input() -> void:
	if Input.is_action_just_pressed("grapple"):
		var mousePos = get_global_mouse_position()
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.new()
		query.from = mousePos
		query.to = mousePos + Vector2.DOWN * 1000
		var result = space_state.intersect_ray(query)
		if result:
			_set_path(result["position"])






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
