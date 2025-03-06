extends Node2D
class_name Pathfinder


var _tile_map: TileMapLayer
var _max_jump_height: int = 4  # Maximum jump height in tiles TODO
var _jump_distance: int = 7    # Maximum jump distance in tiles TODO


var _debug_draw: bool = true
var _path_to_draw: Array = []
var astar = AStar2D.new()


var grid_to_id: Dictionary = {}
var id_to_grid: Dictionary = {}
var id_counter: int = 0
var _used_cells_dict: Dictionary = {}
var _used_cells_vect: Array[Vector2i] = []


func _init(tile_map: TileMapLayer, max_jump_height: int = 4, jump_distance: int = 7):
	_tile_map = tile_map
	_used_cells_vect = _tile_map.get_used_cells()
	
	for c in _used_cells_vect:
		_used_cells_dict[c] = true
	
	_max_jump_height = max_jump_height
	_jump_distance = jump_distance
	print("PathFinder initialized")
	
	_create_grid(0, 200, -100, -1) # TODO, use map size
	_create_connections()


func find_path(start: Vector2, end: Vector2, character_width: int = 1, character_height: int = 2) -> Array:
	var start_grid = _tile_map.local_to_map(start)
	var end_grid = _tile_map.local_to_map(end)
	
	print("Finding path from ", start_grid, " to ", end_grid)
	
	end_grid = _find_top_surface_tile(end_grid)
	if end_grid == Vector2i(-1, -1):
		print("No valid surface tile found")
		return []

	var path = _generate_path(start_grid, end_grid, character_width, character_height)
	
	_path_to_draw = path
	queue_redraw()
	return path


func _find_top_surface_tile(pos: Vector2i) -> Vector2i:
	for y in range(pos.y, pos.y + 100):
		var check_pos = Vector2i(pos.x, y)
		var above_pos = Vector2i(pos.x, y - 1)
		
		if _is_solid(check_pos) and not _is_solid(above_pos):
			return above_pos
	
	return Vector2i(-1, -1)


func _create_grid(x_min: int, x_max: int, y_min: int, y_max: int) -> void:
	astar = AStar2D.new()
	print("start grid")

	grid_to_id = {}
	id_to_grid = {}
	id_counter = 0
	
	for y in range(y_min, y_max + 1):
		for x in range(x_min, x_max + 1):
			var pos = Vector2i(x, y)
			
			if _is_solid(pos):
				continue
			var id = id_counter
			id_counter += 1
			
			astar.add_point(id, Vector2(pos.x, pos.y))
			grid_to_id[pos] = id
			id_to_grid[id] = pos
	print("end grid")


func _create_connections():
	for pos in grid_to_id:
		var id = grid_to_id[pos]
		var is_on_surface = _is_on_surface(pos)
		
		# left/right horizontal neighbors
		for dx in [-1, 1]:
			var neighbor_pos = Vector2i(pos.x + dx, pos.y)
			
			if neighbor_pos in grid_to_id:
				var neighbor_id = grid_to_id[neighbor_pos]
				var neighbor_on_surface = _is_on_surface(neighbor_pos)
				
				if is_on_surface and neighbor_on_surface:
					astar.connect_points(id, neighbor_id, false)
					astar.set_point_weight_scale(neighbor_id, 0.1)
		
		# up/down vertical neighbors
		for dy in [-1, 1]:
			var neighbor_pos = Vector2i(pos.x, pos.y + dy)
			
			if neighbor_pos in grid_to_id:
				var neighbor_id = grid_to_id[neighbor_pos]
				
				# fall down
				if dy == 1:
					astar.connect_points(id, neighbor_id, false)
				
				# jump up
				if dy == -1 and is_on_surface:
					if _can_jump_to(pos, neighbor_pos):
						astar.connect_points(id, neighbor_id, false)
		
		# diagonal neighbors
		for dx in [-1, 1]:
			for dy in [-1, 1]:
				var direct_down = Vector2i(pos.x, pos.y + 1)
				if direct_down in grid_to_id:
					continue
				var neighbor_pos = Vector2i(pos.x + dx, pos.y + dy)
				
				if neighbor_pos in grid_to_id:
					var neighbor_id = grid_to_id[neighbor_pos]
					if _is_diagonal_move_valid(pos, dx, dy):
						if dy == -1 and is_on_surface:
								astar.connect_points(id, neighbor_id, false)
						if dy == 1:
								astar.connect_points(id, neighbor_id, false)
		
		# distant jumps
		if is_on_surface:
			for dx in range(2, _jump_distance):
				for dir_x in [-1, 1]:
					var max_height = _get_max_jump_height_for_distance(dx)
					if max_height <= 0:
						continue
					
					for dy in range(1, max_height):
						var jump_target = Vector2i(pos.x + (dx * dir_x), pos.y - dy)
						if jump_target in grid_to_id:
							if not _is_jump_arc_blocked(pos, jump_target):
								var target_id = grid_to_id[jump_target]
								astar.connect_points(id, target_id, false)
								astar.set_point_weight_scale(target_id, 10)


func _is_diagonal_move_valid(from_pos: Vector2i, dx: int, dy: int) -> bool:
	if dy == -1:
		# diagonal up-right, check for solid tile on right or above
		if dx > 0: 
			if (_is_solid(Vector2i(from_pos.x + 1, from_pos.y -1)) or 
				_is_solid(Vector2i(from_pos.x, from_pos.y - 1))):
				return false
			
		# diagonal up-left, check for solid tile on left or above
		if dx < 0:
			if (_is_solid(Vector2i(from_pos.x - 1, from_pos.y - 1)) or 
				_is_solid(Vector2i(from_pos.x, from_pos.y - 1))):
				return false
	
	if dy == 1:
		# diagonal down-right
		if dx > 0: 
			if (_is_solid(Vector2i(from_pos.x + 1, from_pos.y)) or 
				_is_solid(Vector2i(from_pos.x + 1, from_pos.y + 1))):
				return false
		
		# down left
		if dx < 0: 
			if (_is_solid(Vector2i(from_pos.x - 1, from_pos.y)) or 
				_is_solid(Vector2i(from_pos.x - 1, from_pos.y + 1))):
				return false
	
	return true


func _generate_path(start_grid: Vector2i, end_grid: Vector2i, character_width: int = 1, character_height: int = 1) -> Array:
	# TODO: use character_width and height
	if not start_grid in grid_to_id:
		print("Start position not in grid")
		return []
	if not end_grid in grid_to_id:
		print("end position not in grid")
		return []
	
	var start_id = grid_to_id[start_grid]
	var end_id = grid_to_id[end_grid]
	var id_path = astar.get_id_path(start_id, end_id, true)
	
	if id_path.size() == 0:
		print("No path found")
		return []
	
	var path = []
	var rewrite_last_and_skip_this = false # cuz of jumps that end on same y, otherwise we stop in midair
	for i in range(id_path.size()):
		var id = id_path[i]
		var pos = id_to_grid[id]
		var is_on_surface = _is_on_surface(pos)

		var node = {
			"position": _tile_map.map_to_local(pos),
			"grid_pos": pos,
			"type": "move"
		}
		if rewrite_last_and_skip_this:
			if not is_on_surface:
				continue
			if path.size() > 0:
				var prev_node = path[-1]
				prev_node["position"] = _tile_map.map_to_local(pos)
				prev_node["grid_pos"] = pos
				rewrite_last_and_skip_this = false
				#print("rewritten with : ", pos, ", on i: ", i)
				continue
		
		
		if i > 0:
			var prev_id = id_path[i-1]
			var prev_pos = id_to_grid[prev_id]
			var prev_is_on_surface = _is_on_surface(prev_pos)
			
			if prev_is_on_surface and pos.y < prev_pos.y:
				node["type"] = "jump"
				
				var dx = abs(pos.x - prev_pos.x)
				var dy = prev_pos.y - pos.y
				
				node["height"] = dy
				node["distance"] = dx
				node["jump_force"] = (
					190.0 if dy == 1 and dx <= 3 else
					230.0 if dy == 1 and dx <= 4 else
					270.0 if dy == 1 and dx <= 5 else
					340.0 if dy == 1 and dx <= 6 else
					370.0 if dy == 1 and dx <= 7 else
					275.0 if dy <= 2 and dx <= 3 else
					320.0 if dy <= 2 and dx <= 6 else
					335.0 if dy <= 3 and dx <= 4 else
					380.0
				)
				if not is_on_surface:
					if (i+1) <= id_path.size():
						rewrite_last_and_skip_this = true
						#print("rewrite: ", pos, ", on i: ", i)
			else:
				if not is_on_surface: # skip points in the middle of the air
					continue
		path.append(node)
	
	return path


func _is_on_surface(pos: Vector2i) -> bool:
	return not _is_solid(pos) and _is_solid(Vector2i(pos.x, pos.y + 1))


func _can_jump_to(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	var dx = abs(from_pos.x - to_pos.x)
	var dy = from_pos.y - to_pos.y  # Positive when moving up, cuz eg -1 - -3 == +2
	
	if dy <= 0:
		return false
		
	if dx > _jump_distance:
		return false
	
	var max_height = _get_max_jump_height_for_distance(dx)
	return dy <= max_height


func _get_max_jump_height_for_distance(distance: int) -> int:
	if distance <= 0:
		return _max_jump_height + 1
	elif distance >= _jump_distance:
		return 0
	
	var max_height = 0
	
	match distance:
		1, 2, 3, 4, 5: max_height = 4
		6: max_height = 3
		7: max_height = 2
		8: max_height = 1
		_: max_height = -1
	
	return max_height + 1 # +1 as player height TODO


func _is_jump_arc_blocked(from_pos: Vector2i, to_pos: Vector2i, character_width: int = 1, character_height: int = 1) -> bool:
	var dx = to_pos.x - from_pos.x
	var dy = to_pos.y - from_pos.y  # Negative when jumping up
	
	if abs(dx) <= 1 and abs(dy) <= 1:
		return false
	
	if abs(dx) > _jump_distance or abs(dy) > _max_jump_height:
		return true
	
	var num_points = max(abs(dx) * 10, abs(dy) * 10)
	var prev_cell = from_pos
	
	for i in range(1, num_points + 1):
		var t = float(i) / num_points
		
		var arc_pos = _calculate_jump_arc_point(from_pos, to_pos, t)
		
		var check_cells = [
			Vector2i(int(round(arc_pos.x)), int(round(arc_pos.y))),
			Vector2i(int(round(arc_pos.x)), int(round(arc_pos.y)) - 1),
			Vector2i(int(floor(arc_pos.x)), int(round(arc_pos.y))),
			Vector2i(int(ceil(arc_pos.x)), int(round(arc_pos.y)))
		]
		
		var curr_cell = check_cells[0]
		
		if curr_cell == prev_cell:
			continue
			
		for cell in check_cells:
			if _character_collides_at_position(cell, character_width, character_height):
				return true
		
		# moving diagonally
		if curr_cell.x != prev_cell.x and curr_cell.y != prev_cell.y:
			var move_dx = sign(curr_cell.x - prev_cell.x)
			var move_dy = sign(curr_cell.y - prev_cell.y)
			
			var horiz_pos = Vector2i(curr_cell.x, prev_cell.y)
			if _character_collides_at_position(horiz_pos, character_width, character_height):
				return true
		
		prev_cell = curr_cell
	return false


func _calculate_jump_arc_point(from_pos: Vector2i, to_pos: Vector2i, t: float) -> Vector2:
	var start_x = float(from_pos.x)
	var start_y = float(from_pos.y)
	var end_x = float(to_pos.x)
	var end_y = float(to_pos.y)
	
	var x = lerp(start_x, end_x, t)
	var y = 0.0
	var dy = end_y - start_y
	
	if dy <= 0:  # jumping
		y = start_y + dy * t - abs(dy) * 2 * t * (1 - t)
	else:  # falling
		y = start_y + dy * t - abs(dy) * 0.5 * t * (1 - t)
	return Vector2(x, y)


func _character_collides_at_position(pos: Vector2i, character_width: int, character_height: int) -> bool:
	for w in range(character_width):
		for h in range(character_height):
			var check_pos = Vector2i(pos.x + w, pos.y - h)
			if _is_solid(check_pos):
				return true
	return false


func _is_solid(pos: Vector2i) -> bool:
	return pos in _used_cells_dict


func _draw() -> void:
	if not _debug_draw or _path_to_draw.size() < 2:
		return
	
	for i in range(1, _path_to_draw.size()):
		var prev_pos = _path_to_draw[i-1].position
		var curr_pos = _path_to_draw[i].position
		
		var color = Color.BLUE
		if _path_to_draw[i].has("type"):
			match _path_to_draw[i].type:
				"jump":
					color = Color.RED
				"waypoint":
					color = Color.YELLOW
		
		draw_line(prev_pos, curr_pos, color, 2.0)
		
		draw_circle(curr_pos, 4.0, color)
		
		draw_string(ThemeDB.fallback_font, curr_pos + Vector2(5, -5), str(i), 
					HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
