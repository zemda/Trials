extends CharacterBody2D
class_name Enemy


@export var max_jump_height: int = 4
@export var max_jump_distance: int = 8

@export var player_height: int = 1
@export var player_width: int = 1
@export var debug_draw: bool = true

@onready var _wall_raycast: RayCast2D = $WallDetection
@onready var _player_raycast: RayCast2D = $PlayerDetection

var _player: Player
var _speed: float = 160.0
var _jump_force: float = 375.0

#region States vars
enum EnemyState {
	IDLE,
	MOVE,
	HANGING,
	APPROACHING_CEILING,
	CHASE
}
enum ControlMode {
	MANUAL,
	AUTO_CHASE
}

var _control_mode: int = ControlMode.MANUAL

var _current_state: int = EnemyState.IDLE
#endregion

#region Pathfinding vars
const NO_TARGET: Vector2 = Vector2(-9999999, -9999999)

var _current_path: Array = []
var _current_target: Vector2 = NO_TARGET
var _go_to_position: Vector2 = NO_TARGET

var _padding: float = 2.5
var _finish_padding: float = 5.0
var _stuck_timer: float = 0.0
var _stuck_timeout: float = 0.5

var _path_finder: Pathfinder
var _path_finder_manager: PathfinderManager
var _path_recalculation_timer: float = 0.0
var _path_recalculation_interval: float = 0.5
var _last_path_target: Vector2 = NO_TARGET
var _min_target_movement_for_recalc: float = 32.0 # 2 tiles
#endregion

#region Hanging vars
var _is_hanging: bool = false
var _gravity_enabled: bool = true
var _ceiling_position: Vector2 = Vector2.ZERO
var _approaching_ceiling: bool = false
var _ready_to_attach: bool = false
var _max_ceiling_distance: float = 112.0  # 7 tiles -> 7 * 16
var _hanging_start_interval: float = 5.0
var _hanging_start_timer: float = 0.0
var _tries_to_hang: int = 0
#endregion

#region Shooting vars
@export var _projectile_scene: PackedScene
var _can_shoot: bool = true
var _shoot_cooldown: float = 0.3
var _shoot_timer: float = 0.0
var _shoot_range: float = 200.0
#endregion

#region Player detection vars
var _player_detection_timer: float = 0.0
var _player_detection_interval: float = 0.2
var _player_visible: bool = false
var _player_behind_wall: bool = false
var _player_in_range: bool = false
var _player_chase_distance: float = 320.0  # 15 tiles
var _player_last_known_position: Vector2 = NO_TARGET
#endregion


func _ready() -> void:
	add_to_group("Enemies")


func _physics_process(delta: float) -> void:
	match _current_state:
		EnemyState.IDLE:
			_process_idle_state(delta)
		EnemyState.MOVE:
			_process_move_state(delta)
		EnemyState.HANGING:
			_process_hanging_state()
		EnemyState.APPROACHING_CEILING:
			_process_ceiling_attaching()
		EnemyState.CHASE:
			_process_chase_state(delta)
	
	_update_raycasts()
	_update_player_detection(delta)
	
	_path_recalculation_timer += delta
	
	if _current_state != EnemyState.HANGING:
		_apply_gravity_and_move(delta)
	
	_update_shooting(delta)
	
	if debug_draw:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if _control_mode == ControlMode.MANUAL:
		if event.is_action_pressed("enemy_shoot_test"):
			var click_pos = get_global_mouse_position()
			move_to(click_pos)
		elif event.is_action_pressed("grapple"):
			var click_pos = get_global_mouse_position()
			shoot(click_pos)
		elif event.is_action_pressed("ui_cancel"):
			_toggle_hanging()
	
	if event.is_action_pressed("toggle_enemy_control"):
		toggle_control_mode()


func toggle_control_mode() -> void:
	_tries_to_hang = 0
	if _control_mode == ControlMode.MANUAL:
		_control_mode = ControlMode.AUTO_CHASE
		print("Enemy now in AUTO chase mode")
	else:
		_control_mode = ControlMode.MANUAL
		_clear_path()
		if _current_state == EnemyState.CHASE:
			_change_state(EnemyState.IDLE)
		print("Enemy now in MANUAL control mode")


func _apply_gravity_and_move(delta: float) -> void:
	if not is_on_floor() and _gravity_enabled:
		velocity += get_gravity() * delta
	
	move_and_slide()


func init_references(pf: Pathfinder, player: Player, pfm: PathfinderManager) -> void:
	_path_finder = pf
	_player = player
	_path_finder_manager = pfm



#region State processing
func _process_idle_state(delta: float) -> void:
	velocity.x = 0
	
	if _control_mode == ControlMode.AUTO_CHASE and (_player_visible or _player_behind_wall) and _player != null:
		_change_state(EnemyState.CHASE)
		_tries_to_hang = 0
	if _tries_to_hang < 5 and _control_mode == ControlMode.AUTO_CHASE:
		_toggle_hanging()
	


func _process_move_state(delta: float) -> void:
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
	else:
		velocity.x = 0
		
		if _go_to_position != NO_TARGET:
			if _path_recalculation_timer >= _path_recalculation_interval:
				_recalculate_path()
				_path_recalculation_timer = 0.0
		
		elif _current_path.size() == 0:
			_change_state(EnemyState.IDLE)


func _process_chase_state(delta: float) -> void:
	if _control_mode == ControlMode.MANUAL:
		_change_state(EnemyState.IDLE)
		return
		
	if _player == null:
		_change_state(EnemyState.IDLE)
		return
	
	if _current_target != NO_TARGET:
		_check_if_stuck(delta)
		_move_towards_target()
	
	var distance_to_player = global_position.distance_to(_player.global_position)
	var is_mid_jump = not is_on_floor() and velocity.y != 0
	
	if can_shoot_at_player():
		shoot(_player.global_position + Vector2(0.0, -16.0))
	
	if _player_visible:
		if distance_to_player > 130:
			if (not is_mid_jump) and (_current_target == NO_TARGET or _current_path.size() < 2):
				if _path_recalculation_timer >= _path_recalculation_interval:
					print("Chasing visible player - calculating path")
					move_to(_player.global_position)
					_path_recalculation_timer = 0.0
		else:
			if not is_mid_jump:
				_clear_path()
		
	elif _player_behind_wall and distance_to_player <= _player_chase_distance:
		if (not is_mid_jump) and (_current_target == NO_TARGET or _current_path.size() < 2):
			if _path_recalculation_timer >= _path_recalculation_interval:
				print("Chasing player behind wall - calculating path")
				move_to(_player.global_position)
				_path_recalculation_timer = 0.0
			
	else:
		if _player_last_known_position != NO_TARGET:
			print(abs(_player_last_known_position.x - position.x))
			#print("last knwon .. _current_target: ", _current_target, ", my pos: ", position, ", path size: ", _current_path.size())
			if not is_mid_jump and _go_to_position != _player_last_known_position:
				print("Moving to player's last known position")
				move_to(_player_last_known_position)
			
			if abs(_player_last_known_position.x - position.x) < _padding or _current_target == NO_TARGET or _current_path.size() == 0:
				#print("Player pos: ", _player_last_known_position)
				#print("Enemy pos: ", position, ", global: ", global_position)
				#print(_current_path.size())
				_player_last_known_position = NO_TARGET
		elif _current_path.size() == 0 and _current_target == NO_TARGET and not is_mid_jump:
			_change_state(EnemyState.IDLE)
			velocity.x = 0
		#print("_current_target: ", _current_target, ", my pos: ", position, ", path size: ", _current_path.size())


func _process_hanging_state() -> void:
	velocity = Vector2.ZERO
	var angle := 0 if _current_state != EnemyState.HANGING else 180
	if can_shoot_at_player():
			shoot(_player.global_position + Vector2(0.0, -16.0))
	
	#elif (_player_behind_wall or _player_visible) and _player != null:
		#var distance_to_player = global_position.distance_to(_player.global_position)
		#if distance_to_player <= _player_chase_distance:
			#if randf() < 0.05 * _player_detection_interval:
				#_change_state(EnemyState.IDLE)


func _change_state(new_state: int) -> void:
	if _current_state == EnemyState.HANGING and new_state != EnemyState.HANGING:
		_stop_hanging()
	elif _current_state != EnemyState.HANGING and new_state == EnemyState.HANGING:
		_attach_to_ceiling()
	
	match new_state:
		EnemyState.IDLE:
			pass
		EnemyState.MOVE:
			pass
		EnemyState.CHASE:
			pass
		EnemyState.HANGING:
			if _current_state == EnemyState.CHASE or (_current_target != NO_TARGET and _current_state == EnemyState.MOVE):
				return
		EnemyState.APPROACHING_CEILING:
			if _current_state == EnemyState.CHASE or (_current_target != NO_TARGET and _current_state == EnemyState.MOVE):
				return
	
	_current_state = new_state
#endregion


#region Player detection processing
func _update_raycasts() -> void: # TODO when player hanging, vect must be to opposite dir
	var angle := 0 if _current_state != EnemyState.HANGING else 180
	var adj := Vector2(0.0, 0.0) if _current_state != EnemyState.HANGING else Vector2(0.0, 48.0)
	var target_pos = (_player.global_position - global_position).normalized().rotated(deg_to_rad(angle))
	_player_raycast.target_position = target_pos * 25 * 16 + adj
	_wall_raycast.target_position = target_pos * 25 * 16 + adj
	
	_player_raycast.force_raycast_update()
	_wall_raycast.force_raycast_update()
	
	_player_visible = _is_player_visible()
	_player_behind_wall = _is_player_behind_walls()

func _update_player_detection(delta: float) -> void:
	if _control_mode == ControlMode.MANUAL:
		return
		
	_player_detection_timer += delta
	if _player_detection_timer < _player_detection_interval or _player == null:
		return
	
	_player_detection_timer = 0
	
	var distance_to_player = global_position.distance_to(_player.global_position)
	var player_in_chase_range = distance_to_player <= _player_chase_distance
	
	if _player_visible or _player_behind_wall:
		_player_last_known_position = _player.global_position
		print("updated pos")
		
		if (_player_visible or (_player_behind_wall and player_in_chase_range)) and \
		   _current_state != EnemyState.HANGING and \
		   _current_state != EnemyState.APPROACHING_CEILING:
			if is_on_floor() or _current_state == EnemyState.IDLE:
				_change_state(EnemyState.CHASE)


func _is_player_visible() -> bool: # TODO when hanging vect must be opposite dir
	if _player_raycast.is_colliding() and _player_raycast.get_collider() == _player:
		if _wall_raycast.is_colliding():
			var wall_distance = _wall_raycast.get_collision_point().distance_to(global_position)
			var player_distance = _player.global_position.distance_to(global_position)
			return wall_distance > player_distance
		return true
	return false


func _is_player_behind_walls() -> bool:
	if _player == null or _player_visible:
		return false
	
	if _wall_raycast.is_colliding() and \
	_player_raycast.is_colliding() and \
	global_position.distance_to(_player.global_position) < 160:
		return true
	return false

#endregion


#region Shooting processing
func can_shoot_at_player() -> bool:
	if not _can_shoot or not _projectile_scene or _player == null:
		return false
		
	var distance_to_player = global_position.distance_to(_player.global_position)
	if distance_to_player > _shoot_range:
		return false
	
	if not _player_visible:
		return false
	
	return true


func shoot(target_position: Vector2) -> void:
	if not _can_shoot or not _projectile_scene:
		return
	
	var projectile = _projectile_scene.instantiate()
	
	if get_tree().current_scene:
		get_tree().current_scene.add_child(projectile)
	else:
		get_parent().add_child(projectile)
	
	projectile.is_shooter_on_ceiling = _current_state == EnemyState.HANGING
	projectile.global_position = global_position
	projectile.launch(target_position)
	
	_can_shoot = false
	_shoot_timer = 0.0

func _update_shooting(delta: float) -> void:
	if not _can_shoot:
		_shoot_timer += delta
		if _shoot_timer >= _shoot_cooldown:
			_can_shoot = true
#endregion


#region Hanging processing
func _toggle_hanging() -> void:
	if _current_state == EnemyState.HANGING:
		_change_state(EnemyState.IDLE)
	elif _current_state == EnemyState.IDLE or _control_mode == ControlMode.MANUAL or _current_state:
		var found_ceiling = _find_ceiling()
		_tries_to_hang += 1
		print("tried, ", _tries_to_hang)
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
	if _current_state == EnemyState.HANGING or _current_state == EnemyState.APPROACHING_CEILING:
		return
	
	if _control_mode == ControlMode.MANUAL:
		_approaching_ceiling = true
		_change_state(EnemyState.APPROACHING_CEILING)
		print("Manual hanging started")
		return
	
	if _player_visible and _current_state == EnemyState.CHASE:
		return
		
	_approaching_ceiling = true
	_change_state(EnemyState.APPROACHING_CEILING)
	print("Auto hanging started")


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


func _process_ceiling_attaching() -> void:
	print("trying to ceil")
	if _ready_to_attach:
		if abs(global_position.y - _ceiling_position.y) < 10:
			_attach_to_ceiling()
			_change_state(EnemyState.HANGING)
	
	elif is_on_floor() and abs(global_position.x - _ceiling_position.x) < 16:
		print("In position below ceiling, jumping up")
		_ready_to_attach = true
		velocity.y = -_jump_force * 1.2
		
		if abs(global_position.x - _ceiling_position.x) > 5:
			velocity.x = (_ceiling_position.x - global_position.x) * 3
		
		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees", 180, 0.3)
	
	elif _current_target == NO_TARGET and _current_path.size() == 0 and is_on_floor():
		var pos_below_ceiling = Vector2(_ceiling_position.x, _ceiling_position.y + 32)
		
		var direction = sign(pos_below_ceiling.x - global_position.x)
		velocity.x = direction * _speed
		
		if abs(global_position.x - pos_below_ceiling.x) > 48:
			move_to(pos_below_ceiling)
#endregion


#region Pathfinding processing
func _move_towards_target() -> void:
	if _current_target == NO_TARGET:
		velocity.x = 0
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


func _next_point() -> void:
	if _current_path.size() == 0:
		_current_target = NO_TARGET
		
		if _current_state == EnemyState.MOVE:
			_change_state(EnemyState.IDLE)
		
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
			velocity.y = -jump_force
	
	_current_target = next_node.position


func _check_if_stuck(delta: float) -> void:
	if _current_path.size() > 0 and abs(velocity.x) < 10.0 and is_on_floor():
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
	if _go_to_position != NO_TARGET and _path_finder:
		var new_path = _path_finder.find_path(
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
			_change_state(EnemyState.IDLE)


func move_to(destination: Vector2) -> void:
	if _current_state == EnemyState.HANGING:
		return
	
	if is_on_floor() or _current_path.size() == 0:
		_current_path.clear()
		_current_target = NO_TARGET
	else:
		print("Skipping move_to since we are in a jump or we have a path")
		return
		
	_stuck_timer = 0
	
	if _path_finder:
		_go_to_position = destination
		var new_path = _path_finder.find_path(
			global_position,
			destination,
			player_width,
			player_height
		)

		if new_path.size() > 0:
			_current_path = new_path
			_next_point()
			
			if _current_state != EnemyState.CHASE and _current_state != EnemyState.MOVE:
				_change_state(EnemyState.MOVE)
		else:
			_go_to_position = NO_TARGET

#endregion


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
	
	if _current_target != NO_TARGET:
		draw_circle(_current_target - global_position, 5.0, Color.BLUE)
	
	var debug_text = "Path: " + str(_current_path.size()) 
	debug_text += " State: " + str(EnemyState.keys()[_current_state])
	debug_text += " Mode: " + str(ControlMode.keys()[_control_mode])
	draw_string(ThemeDB.fallback_font, Vector2(-70, -50), debug_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	if _player != null:
		# Green = directly visible, Gray = behind wall but chaseable, Red = not visible
		var status_color
		if _player_visible:
			status_color = Color.GREEN
		elif _player_behind_wall:
			status_color = Color.GRAY
		else:
			status_color = Color.RED
			
		draw_circle(Vector2(0, -10), 3.0, status_color)
	
	
