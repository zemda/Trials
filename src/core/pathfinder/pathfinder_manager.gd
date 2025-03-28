extends Node2D
class_name PathfinderManager

@export var tile_map: TileMapLayer
@export var debug_draw_path: bool = true
@export var max_jump_height: int = 4
@export var max_jump_distance: int = 7 # TODO: might do per enemy

var _player: Player
var _pathfinder: Pathfinder
var _enemies: Array[Enemy] = []


func _ready() -> void:
	_pathfinder = Pathfinder.new(tile_map, max_jump_height, max_jump_distance)
	add_child(_pathfinder)
	_pathfinder._debug_draw = debug_draw_path


func set_player(player_ref):
	if is_instance_valid(player_ref):
		_player = player_ref
		return true
	else:
		return false


func register_character(enemy: Enemy) -> void:
	enemy.init_references(_pathfinder, _player, self)
	_enemies.append(enemy)


func register_existing_characters() -> void:
	var all_characters = get_tree().get_nodes_in_group("Enemies")
	for character in all_characters:
		register_character(character)


func unregister_characters() -> void:
	_enemies.clear()


func update_pathfinder() -> void:
	if _pathfinder:
		_pathfinder.queue_free()
	
	_pathfinder = Pathfinder.new(tile_map, max_jump_height, max_jump_distance)
	add_child(_pathfinder)
	_pathfinder._debug_draw = debug_draw_path
	
	for enemy in _enemies:
		enemy.init_references(_pathfinder, _player, self)
