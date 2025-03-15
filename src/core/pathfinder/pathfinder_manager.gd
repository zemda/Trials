extends Node2D
class_name PathfinderManager

@export var tile_map: TileMapLayer
var player: Player

@export var debug_draw_path: bool = true
@export var max_jump_height: int = 4
@export var max_jump_distance: int = 7 # TODO: might do per enemy

var pathfinder: Pathfinder
var enemies: Array[Enemy] = []


func _ready() -> void:
	pathfinder = Pathfinder.new(tile_map, max_jump_height, max_jump_distance)
	add_child(pathfinder)
	pathfinder._debug_draw = debug_draw_path
	register_existing_characters()


func set_player(player_ref):
	if is_instance_valid(player_ref):
		player = player_ref
		return true
	else:
		return false


func register_character(enemy: Enemy) -> void:
	enemy.init_references(pathfinder, player, self)
	enemies.append(enemy)


func register_existing_characters() -> void:
	var all_characters = get_tree().get_nodes_in_group("Enemies")
	for character in all_characters:
		register_character(character)


func unregister_characters() -> void:
	enemies.clear()


func update_pathfinder() -> void:
	if pathfinder:
		pathfinder.queue_free()
	
	pathfinder = Pathfinder.new(tile_map, max_jump_height, max_jump_distance)
	add_child(pathfinder)
	pathfinder._debug_draw = debug_draw_path
	
	for enemy in enemies:
		enemy.init_references(pathfinder, player, self)
