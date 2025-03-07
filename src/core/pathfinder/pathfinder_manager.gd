extends Node2D
class_name PathfinderManager

@export var tile_map: TileMapLayer
@export var player: Player

@export var debug_draw_path: bool = true
@export var max_jump_height: int = 4
@export var max_jump_distance: int = 7 # TODO: might do per enemy

var pathfinder: Pathfinder
var enemies: Array[Enemy] = []
var _update_timer: float = 0.0
var _following_enemies: Array[Enemy] = []


func _ready() -> void:
	pathfinder = Pathfinder.new(tile_map, max_jump_height, max_jump_distance)
	add_child(pathfinder)
	pathfinder._debug_draw = debug_draw_path
	_register_existing_characters()


func _physics_process(delta: float) -> void:
	if _following_enemies.size() > 0 and player:
		_update_timer += delta
		if _update_timer >= 0.5:
			_update_timer = 0.0
			for enemy in _following_enemies:
				enemy.move_to(player.global_position)


func register_character(enemy: Enemy) -> void:
	enemy.init_references(pathfinder, player, self)
	enemies.append(enemy)


func unregister_character(character: Enemy) -> void:
	if character in enemies:
		enemies.erase(character)


func _register_existing_characters() -> void:
	var all_characters = get_tree().get_nodes_in_group("Enemies")
	for character in all_characters:
		register_character(character)


func move_character_to(enemy: Enemy, target_pos: Vector2) -> void:
	if enemy in enemies:
		enemy.move_to(target_pos)


func move_all_enemies_to(target_pos: Vector2) -> void:
	for enemy in enemies:
		enemy.move_to(target_pos)


func make_enemy_follow_player(enemy: Enemy, follow_distance: float = 16.0) -> void:
	if player and enemy in enemies:
		enemy.move_to(player.global_position)
		
		if not enemy in _following_enemies:
			_following_enemies.append(enemy)


func stop_enemy_following(enemy: Enemy) -> void:
	if enemy in _following_enemies:
		_following_enemies.erase(enemy)


func update_pathfinder() -> void:
	if pathfinder:
		pathfinder.queue_free()
	
	pathfinder = Pathfinder.new(tile_map, max_jump_height, max_jump_distance)
	add_child(pathfinder)
	pathfinder._debug_draw = debug_draw_path
	
	for enemy in enemies:
		enemy.init_pathfinder(pathfinder)
