extends Area2D
class_name DestructiblePlatform

@export var platform_length: int = 1
@export var destruction_time: float = 1.5

var _destruction_started: bool = false

const SINGLE_TILE_COORDS = Vector2i(3, 0)
const LEFT_EDGE_COORDS = Vector2i(0, 0)
const MIDDLE_TILE_COORDS = Vector2i(1, 0)
const RIGHT_EDGE_COORDS = Vector2i(2, 0)

const TILE_SOURCE_ID = 1


func _init() -> void:
	add_to_group("storable")


func _ready() -> void:
	_create_platform_tiles()
	$CollisionShape2D.scale.x = platform_length
	body_entered.connect(_on_body_entered)


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


func _on_body_entered(body: Node2D) -> void:
	if body is Player and !_destruction_started:
		_destruction_started = true
		var timer = get_tree().create_timer(destruction_time)
		timer.timeout.connect(_destroy_platform)


func _destroy_platform() -> void:
	queue_free() # TODO rest, anim, blabla
