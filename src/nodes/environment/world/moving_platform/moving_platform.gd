extends Node2D
class_name MovingPlatform


@export var platform_length: int = 3
@export var speed_not_loop: float = 0.2
@export var loop_speed: float = 0.5
@export var loop: bool = false

@onready var _path_follow: PathFollow2D = $PathFollow2D
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

const SINGLE_TILE_COORDS = Vector2i(3, 0)
const LEFT_EDGE_COORDS = Vector2i(0, 0)
const MIDDLE_TILE_COORDS = Vector2i(1, 0)
const RIGHT_EDGE_COORDS = Vector2i(2, 0)

const TILE_SOURCE_ID = 1



func _ready() -> void:
	if not loop:
		_animation_player.play("move")
		_animation_player.speed_scale = loop_speed
		set_process(false)
	
	_path_follow.loop = loop
	_path_follow.rotates = false
	
	_create_platform_tiles()


func _process(delta: float) -> void:
	_path_follow.progress += speed_not_loop


func _create_platform_tiles() -> void:
	var tile_layer = $base
	
	for i in range(platform_length):
		var coords = Vector2i(i, 0)
		var atlas_coords
		
		if platform_length == 1:
			atlas_coords = SINGLE_TILE_COORDS
		elif i == 0:
			atlas_coords = LEFT_EDGE_COORDS
		elif i == platform_length - 1:
			atlas_coords = RIGHT_EDGE_COORDS
		else:
			atlas_coords = MIDDLE_TILE_COORDS
			
		tile_layer.set_cell(coords, TILE_SOURCE_ID, atlas_coords)
