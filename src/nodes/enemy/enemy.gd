extends CharacterBody2D
class_name Enemy

const NO_TARGET: Vector2 = Vector2(-9999999, -9999999)

var _current_path: Array = []
var _current_target: Vector2 = NO_TARGET
var _go_to_position: Vector2 = NO_TARGET

var _speed: float = 160.0
var _jump_force: float = 375.0

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

var _is_hanging: bool = false
var _gravity_enabled: bool = true
var _ceiling_position: Vector2 = Vector2.ZERO
var _approaching_ceiling: bool = false
var _ready_to_attach: bool = false
var _max_ceiling_distance: float = 112.0  # 7 tiles -> 7 * 16



func _physics_process(delta: float) -> void:
	if _is_hanging:
		_process_hanging_state()
	elif _approaching_ceiling:
		_process_ceiling_attaching()
	
	if not _is_hanging:
		_process_normal_movement(delta)
	
	_apply_gravity_and_move(delta)
	
	_check_handing_state()
	
	if debug_draw:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("grapple"):
		var click_pos = get_global_mouse_position()
		move_to(click_pos)
	if event.is_action_pressed("ui_cancel"):
		_toggle_hanging()


func _apply_gravity_and_move(delta: float) -> void:
	if not _is_hanging and not is_on_floor() and _gravity_enabled:
		velocity += get_gravity() * delta
	
	move_and_slide()


func init_pathfinder(finder: Pathfinder) -> void:
	path_finder = finder



# ----- HANGING -----
func _toggle_hanging() -> void:
	if _is_hanging:
		_stop_hanging()
	elif not _approaching_ceiling and _current_target == NO_TARGET:
		var found_ceiling = _find_ceiling()
		if found_ceiling:
			_start_hanging()

func _find_ceiling() -> bool:
	var space_state = get_world_2d().direct_space_state
	var start_pos = global_position
	var end_pos = start_pos + Vector2(0, -_max_ceiling_distance)
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result and result.has("position"):
		_ceiling_position = result.position
		return true
	
	return false

func _start_hanging() -> void:
	if _is_hanging or _approaching_ceiling:
		return
	
	_approaching_ceiling = true
	
	# TODO: find a ceiling pos, use move_to() under it and attach... or go back to spawn ceiling

func _attach_to_ceiling() -> void:
	_is_hanging = true
	_approaching_ceiling = false
	_ready_to_attach = false
	_gravity_enabled = false
	velocity = Vector2.ZERO

func _stop_hanging() -> void:
	if not _is_hanging:
		return
	
	_is_hanging = false
	_gravity_enabled = true
	velocity.y = 10
	
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", 0, 0.3)

func _process_hanging_state() -> void:
	velocity = Vector2.ZERO

func _process_ceiling_attaching() -> void:
	if _ready_to_attach:
		if abs(global_position.y - _ceiling_position.y) < 10:
			_attach_to_ceiling()
	
	elif is_on_floor() and abs(global_position.x - _ceiling_position.x) < 16:
		print("In position below ceiling, jumping up")
		_ready_to_attach = true
		velocity.y = -_jump_force * 1.2
		
		if abs(global_position.x - _ceiling_position.x) > 5:
			velocity.x = (_ceiling_position.x - global_position.x) * 3
		
		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees", 180, 0.5)
	
	elif _current_target == NO_TARGET and _current_path.size() == 0 and is_on_floor():
		var pos_below_ceiling = Vector2(_ceiling_position.x, _ceiling_position.y + 32)
		
		var direction = sign(pos_below_ceiling.x - global_position.x)
		velocity.x = direction * _speed
		
		if abs(global_position.x - pos_below_ceiling.x) > 48:
			move_to(pos_below_ceiling)

func _check_handing_state() -> void:
	if _ready_to_attach and is_on_floor():
		_ready_to_attach = false
		
		if _approaching_ceiling:
			_start_hanging()


# ----- PATHFINDING && MOVING -----
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
	if _is_hanging:
		return
	
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

func _process_normal_movement(delta: float) -> void:
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
	else:
		if not _approaching_ceiling:
			velocity.x = 0
			
		if _go_to_position != NO_TARGET:
			if abs(_go_to_position.x - position.x) > _finish_padding * 2:
				_recalculate_path()
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
