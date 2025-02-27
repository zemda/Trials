extends Node2D


var _cell_size: int = 16
var _jump_height: int = 2        # in "tiles"
var _jump_distance: int = 3      # in "tiles", meaning that excluding tile i am at i can jump jump_distance further
var _tile_map: TileMapLayer
var _graph: AStar2D
var _show_lines: bool = true
var _used_cells: Array[Vector2i]
var _used_cells_dict: Dictionary
var _walkable_cells: Array[Vector2i]


# track tile <-> point_id
var _tile_to_pid: Dictionary = {}
var _pid_to_tile: Dictionary = {}

const MARKER = preload("res://TEST.tscn")


func _ready() -> void:
	_graph = AStar2D.new()
	_tile_map = get_parent().get_node("Map").get_node("base")
	
	_used_cells = _tile_map.get_used_cells()
	for cell in _used_cells:
		_used_cells_dict[cell] = true
	
	_walkable_cells = _get_walkable_cells()
	
	# Wait a bit so collisions exist, if needed
	#var t = Timer.new()
	#t.wait_time = 0.2
	#t.one_shot = true
	#add_child(t)
	#t.start()
	#await t.timeout
	
	
	print("start map creation")
	_create_map()
	print("map done")
	_create_connections()
	print("connections done")
	
	if _show_lines:
		queue_redraw()


func find_path(start: Vector2, end: Vector2) -> Array:
	var start_id = _graph.get_closest_point(start)
	var end_id = _graph.get_closest_point(end)
	
	if start_id == -1 or end_id == -1:
		print("No valid start or end point found")
		return []
		
	var id_path = _graph.get_id_path(start_id, end_id)
	if id_path.is_empty():
		print("No path found between points")
		return []
	
	var actions = []
	var prev_tile = null
	
	for i in range(id_path.size()):
		var pid = id_path[i]
		var pos = _graph.get_point_position(pid)
		var tile = _pid_to_tile[pid]
		
		if prev_tile != null:
			var dx = tile.x - prev_tile.x
			var dy = tile.y - prev_tile.y
			
			# Check if we need to jump
			var need_jump = false
			
			# CASE 1: Horizontal gap - need jump when gap is 2 or more tiles
			if dy == 0 and abs(dx) >= 2:
				if abs(dx) <= _jump_distance:
					# Check if theres a walkable path through adjacent tiles
					need_jump = true
					
					for step in range(1, abs(dx)):
						var check_x = prev_tile.x + step * sign(dx)
						var check_tile = Vector2i(check_x, prev_tile.y)
						
						# If theres a walkable tile in between, we dont need to jump
						if check_tile in _tile_to_pid:
							need_jump = false
							break
				else:
					# Too far to jump
					need_jump = false
			
			# CASE 2: Going up diagonally (must have horizontal movement)
			elif dy < 0 and abs(dx) >= 1:
				need_jump = true
			
			# CASE 3: Going down with horizontal movement
			elif dy > 0 and abs(dx) >= 1:
				need_jump = false
			
			if need_jump:
				actions.append(null)
		
		actions.append(pos + Vector2(0, _cell_size * 0.2))
		prev_tile = tile
	
	actions.append(end + Vector2(0, _cell_size * 0.2))
	return actions


func _get_walkable_cells() -> Array[Vector2i]:
	var walkable: Array[Vector2i] = []
	for cell in _used_cells:
		var above = Vector2i(cell.x, cell.y - 1)
		if not above in _used_cells_dict:
			walkable.append(cell)
	return walkable


func _create_map() -> void:
	for c in _walkable_cells:
		_add_point_to_graph(c)


func _add_point_to_graph(tile_coords: Vector2i) -> void:
	var tile_above = Vector2i(tile_coords.x, tile_coords.y - 1)
	var local = _tile_map.map_to_local(tile_above)
	var world = _tile_map.to_global(local)
	
	var pid = _graph.get_available_point_id()
	_graph.add_point(pid, world)
	_tile_to_pid[tile_coords] = pid
	_pid_to_tile[pid] = tile_coords
	
	if _show_lines:
		var mark = MARKER.instantiate()
		mark.position = world + Vector2(0, _cell_size * 0.2)
		call_deferred("add_child", mark)


func _create_connections() -> void:
	var tile_grid_dict = {}
	for tile_pos in _tile_to_pid.keys():
		tile_grid_dict[tile_pos] = _tile_to_pid[tile_pos]
	
	for tile_pos in _tile_to_pid.keys():
		var idA = _tile_to_pid[tile_pos]
		
		# 1: Only check direct neighbors for walkable connections (±1 in X)
		for dx in [-1, 1]:
			var neighbor_pos = Vector2i(tile_pos.x + dx, tile_pos.y)
			if neighbor_pos in tile_grid_dict:
				var idB = tile_grid_dict[neighbor_pos]
				_graph.connect_points(idA, idB)
		
		# 2: Only check specific positions for jump connections
		for jump_x in range(2, _jump_distance + 1):
			for direction in [-1, 1]:
				var jump_pos = Vector2i(tile_pos.x + (jump_x * direction), tile_pos.y)
				
				# Only process if this jump destination exists
				if jump_pos in tile_grid_dict:
					# Check if theres a walkable path instead
					var needs_jump = true
					for step in range(1, jump_x):
						var step_pos = Vector2i(tile_pos.x + (step * direction), tile_pos.y)
						if step_pos in tile_grid_dict:
							needs_jump = false
							break
					
					if needs_jump:
						var idB = tile_grid_dict[jump_pos]
						_graph.connect_points(idA, idB)
		
		# 3: Diagonal jumps upward
		for jump_y in range(1, _jump_height + 1):
			for jump_x in range(1, _jump_distance + 1):
				for direction in [-1, 1]:
					var jump_pos = Vector2i(tile_pos.x + (jump_x * direction), tile_pos.y - jump_y)
					
					# Only process if this diagonal jump destination exists
					if jump_pos in tile_grid_dict:
						# Check for clearance above the player
						var has_clearance = true
						for y_check in range(1, jump_y + 1):
							var check_pos = Vector2i(tile_pos.x, tile_pos.y - y_check)
							if check_pos in _used_cells_dict:
								has_clearance = false
								break
						
						if has_clearance and not _is_blocked(tile_pos, jump_pos):
							var idB = tile_grid_dict[jump_pos]
							_graph.connect_points(idA, idB)
		
		# 4: Diagonal movement downward
		for jump_y in range(1, _jump_height + 1):
			for jump_x in range(1, _jump_distance + 1):
				for direction in [-1, 1]:
					var jump_pos = Vector2i(tile_pos.x + (jump_x * direction), tile_pos.y + jump_y)
					
					# Only process if this diagonal down destination exists
					if jump_pos in tile_grid_dict:
						# Check if were at an edge
						var edge_pos = Vector2i(tile_pos.x + direction, tile_pos.y)
						var at_edge = not edge_pos in _used_cells_dict
						
						if at_edge:
							# Check for a clear path
							var path_is_clear = true
							
							# Check if the tiles in between are clear
							for x_off in range(1, jump_x + 1):
								var x_pos = tile_pos.x + (x_off * direction)
								
								for y_off in range(0, jump_y):
									var check_pos = Vector2i(x_pos, tile_pos.y + y_off)
									if check_pos in _used_cells_dict:
										path_is_clear = false
										break
								
								if not path_is_clear:
									break
							
							if path_is_clear and _has_space_for_drop(tile_pos, jump_pos):
								var idB = tile_grid_dict[jump_pos]
								_graph.connect_points(idA, idB)
	
	# 5: Drop connections
	_create_drop_connections(tile_grid_dict)


func _create_drop_connections(tile_grid_dict: Dictionary) -> void:
	for tile_pos in tile_grid_dict.keys():
		var idA = tile_grid_dict[tile_pos]
		
		# Check both left and right for ledges
		for direction in [-1, 1]:
			var side_pos = Vector2i(tile_pos.x + direction, tile_pos.y)
			var above_side_pos = Vector2i(tile_pos.x + direction, tile_pos.y - 1)
			
			var is_ledge = not side_pos in _used_cells_dict and not above_side_pos in _used_cells_dict
			
			if is_ledge:
				_find_drop_target(idA, tile_pos, direction, tile_grid_dict)


func _find_drop_target(idA: int, tile_pos: Vector2i, direction: int, tile_grid_dict: Dictionary) -> void:
	var max_drop_distance = 3
	var max_drop_height = 10

	# First, find the highest, topmost, target at each X position
	var highest_targets = {}  # Store highest target by X position
	
	for drop_distance in range(1, max_drop_distance + 1):
		var target_x = tile_pos.x + (direction * drop_distance)
		
		for drop_height in range(1, max_drop_height + 1):
			var target_pos = Vector2i(target_x, tile_pos.y + drop_height)
			
			if target_pos in tile_grid_dict:
				# If we havent found a target at this X yet, or if this one is higher (lower Y value)
				if not target_x in highest_targets or target_pos.y < highest_targets[target_x].y:
					highest_targets[target_x] = {
						"y": target_pos.y,
						"pos": target_pos,
						"id": tile_grid_dict[target_pos]
					}
	
	var x_positions = highest_targets.keys()
	var sorted_x = []
	
	for x in x_positions:
		var index = 0
		while index < sorted_x.size() and abs(x - tile_pos.x) > abs(sorted_x[index] - tile_pos.x):
			index += 1
		sorted_x.insert(index, x)
	
	# Create connections to the highest targets
	var targets_found = 0
	for target_x in sorted_x:
		var target = highest_targets[target_x]
		var idB = target.id
		
		var has_clearance = true
		# Check the vertical drop path (TODO: not accurate for eg x distance 3, since it doesnt check the distance 2)
		for y in range(1, target.y - tile_pos.y):
			var check_pos = Vector2i(target.pos.x, tile_pos.y + y)
			if check_pos in _used_cells_dict:
				has_clearance = false
				break
		
		if has_clearance and not _graph.are_points_connected(idA, idB):
			_graph.connect_points(idA, idB, false)
			
			targets_found += 1
			if targets_found >= 3:
				return  # Limit to 3 connections per ledge direction

# Check if theres a block in the way for jumping TODO: improve
func _is_blocked(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	# Calc jump arc and check for obstacles
	var dx = to_tile.x - from_tile.x
	var dy = to_tile.y - from_tile.y
	
	if dx == 0:
		# Vertical jump - check all points in between
		var y_step = sign(dy)
		for y in range(from_tile.y + y_step, to_tile.y, y_step):
			var check_tile = Vector2i(from_tile.x, y)
			if check_tile in _used_cells_dict:
				return true
		return false
	
	# For a simple diagonal jump, we only need to check the target tile
	if abs(dx) == 1 and dy == -1:
		return false
	
	# Check all tiles in the path
	for x in range(min(from_tile.x, to_tile.x), max(from_tile.x, to_tile.x) + 1):
		if x == from_tile.x:
			continue
			
		# Calculate approximate y position during jump
		var t = float(x - from_tile.x) / dx
		
		var arc_height = 0
		if dy < 0:
			arc_height = abs(dy) * 0.25 * sin(t * PI)
		
		var y = from_tile.y + (dy * t) - arc_height
		var check_y = int(round(y))
		
		if x == to_tile.x and check_y == to_tile.y:
			continue
		
		# Check for a character height (just 1 tile for the basic check)
		var check_tile = Vector2i(x, check_y)
		if check_tile in _used_cells_dict:
			return true
	
	return false


func _has_space_for_drop(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	var dx = to_tile.x - from_tile.x
	
	# First, ensure theres actually a path to drop down
	# Check the entire column from starting height to landing height
	for y in range(from_tile.y + 1, to_tile.y):
		var check_tile = Vector2i(from_tile.x, y)
		if check_tile in _used_cells_dict:
			return false
	
	# Then check for horizontal movement
	if abs(dx) > 0:
		# For each step in the horizontal direction
		for step in range(1, abs(dx) + 1):
			var x = from_tile.x + (step * sign(dx))
			
			# Check the entire vertical column at this horizontal position
			for y in range(from_tile.y, to_tile.y + 1):
				var check_tile = Vector2i(x, y)
				
				if check_tile == to_tile:
					continue
					
				if check_tile in _used_cells_dict:
					return false
			
			# Check a fixed height (3 tiles) above this position for clearance
			for h in range(1, 4):
				var check_tile = Vector2i(x, from_tile.y - h)
				if check_tile in _used_cells_dict:
					return false
	
	return true


func _draw() -> void:
	if not _show_lines:
		return
		
	var pts = _graph.get_point_ids()
	for idA in pts:
		var pA = _graph.get_point_position(idA)
		var tileA = _pid_to_tile[idA]
		
		var connections = _graph.get_point_connections(idA)
		for idB in connections:
			var pB = _graph.get_point_position(idB)
			var tileB = _pid_to_tile[idB]
			
			var dx = tileB.x - tileA.x
			var dy = tileB.y - tileA.y
			
			# Check if its a one-way connection (drop)
			var is_bidirectional = _graph.are_points_connected(idB, idA)
			
			# Color scheme:
			# Blue: Adjacent walkable tiles (dx=1, same Y)
			# Red: Requires jump (horizontal gap or up)
			# Green: Walking down diagonally
			# Pink: One-way drop connection, probably all the time handled with green
			
			var color
			if not is_bidirectional:
				color = Color.PINK
			elif dy == 0 and abs(dx) == 1:
				color = Color.BLUE
			elif (dy == 0 and abs(dx) > 1) or dy < 0:
				color = Color.DARK_RED
			else:
				color = Color.GREEN
				
			draw_line(pA, pB, color, 1)
