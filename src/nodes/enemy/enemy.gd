extends CharacterBody2D
class_name Enemy

@export var max_jump_height: int = 4
@export var max_jump_distance: int = 8

@export var player_height: int = 1
@export var player_width: int = 1
@export var debug_draw: bool = true

@onready var _wall_raycast: RayCast2D = $WallDetection
@onready var _player_raycast: RayCast2D = $PlayerDetection
@onready var fsm: FSM = $FSM

var _player: Player
var _path_finder: Pathfinder
var _path_finder_manager: PathfinderManager
var _speed: float = 160.0
var _jump_force: float = 375.0


var _player_visible: bool = false
var _player_behind_wall: bool = false
var _player_chasing_distance: float = 320.0 # TODO use this var, test the distances etc
var _player_last_known_position: Vector2 = Vector2(-9999999, -9999999)  # NO_TARGET constant


var _ceiling_position: Vector2 = Vector2.ZERO
var _max_ceiling_distance: float = 112.0
var _gravity_enabled: bool = true


@export var _projectile_scene: PackedScene
var _can_shoot: bool = true
@export var _shoot_cooldown: float = 1.5
var _shoot_timer: float = 0.0
var _shoot_range: float = 200.0


func _ready() -> void:
	add_to_group("Enemies")
	add_to_group("storable")
	fsm.set_host(self)


func _physics_process(delta: float) -> void:
	update_raycasts()
	update_player_detection(delta)
	
	if _gravity_enabled:
		apply_gravity(delta)
	
	move_and_slide()
	
	update_shooting(delta)
	
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false
	
	if debug_draw:
		queue_redraw()


func apply_gravity(delta: float) -> void:
	if not is_on_floor() and _gravity_enabled:
		velocity += get_gravity() * delta


func init_references(pf: Pathfinder, player: Player, pfm: PathfinderManager) -> void:
	_path_finder = pf
	_player = player
	_path_finder_manager = pfm


func update_raycasts() -> void:
	if _player != null:
		var target_pos = (_player.global_position - global_position).normalized()
		_player_raycast.target_position = target_pos * 25 * 16
		_wall_raycast.target_position = target_pos * 25 * 16
	
	_player_raycast.force_raycast_update()
	_wall_raycast.force_raycast_update()
	
	_player_visible = is_player_visible()
	_player_behind_wall = is_player_behind_walls()


func update_player_detection(_delta: float) -> void:
	if _player == null:
		return
	
	if _player_visible or _player_behind_wall:
		_player_last_known_position = _player.global_position


func is_player_visible() -> bool:
	if _player == null:
		return false
		
	if _player_raycast.is_colliding() and _player_raycast.get_collider() == _player:
		if _wall_raycast.is_colliding():
			var wall_distance = _wall_raycast.get_collision_point().distance_to(global_position)
			var player_distance = _player.global_position.distance_to(global_position)
			return wall_distance > player_distance
		return true
	return false


func is_player_behind_walls() -> bool:
	if _player == null or _player_visible:
		return false
	
	if _wall_raycast.is_colliding() and \
		_player_raycast.is_colliding() and \
		global_position.distance_to(_player.global_position) < 160:
		return true
	return false


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
	
	projectile.is_shooter_on_ceiling = fsm.current_state.state_name == "LURKING"
	projectile.global_position = global_position
	projectile.launch(target_position, global_position)
	
	_can_shoot = false
	_shoot_timer = 0.0


func update_shooting(delta: float) -> void:
	if not _can_shoot:
		_shoot_timer += delta
		if _shoot_timer >= _shoot_cooldown:
			_can_shoot = true


func handle_shooting() -> void:
	if can_shoot_at_player():
		shoot(_player.global_position + Vector2(0.0, -16.0))


func find_ceiling() -> bool:
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


func _draw() -> void:
	if not debug_draw or not OS.is_debug_build():
		return
	
	var debug_text = "State: " + str(fsm.current_state.state_name)
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
