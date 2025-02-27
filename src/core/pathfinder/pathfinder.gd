extends Node2D

var cell_size: int = 16
var jump_height: int = 2        # in "tiles"
var jump_distance: int = 3      # in "tiles", meaning that excluding tile i am at i can jump jump_distance further
var tile_map: TileMapLayer
var graph: AStar2D
var show_lines: bool = true

# track tile <-> point_id
var tile_to_pid: Dictionary = {}
var pid_to_tile: Dictionary = {}

const MARKER = preload("res://TEST.tscn")

func _ready():
	graph = AStar2D.new()
	tile_map = get_parent().get_node("Map").get_node("base")
	
	# Wait a bit so collisions exist, if needed
	#var t = Timer.new()
	#t.wait_time = 0.2
	#t.one_shot = true
	#add_child(t)
	#t.start()
	#await t.timeout
	
	print("start map creation")
	create_map()
	print("map done")
	create_connections()
	print("connections done")
	print("Total points:", graph.get_point_count())
	if show_lines:
		queue_redraw()

func findPath(start: Vector2, end: Vector2) -> Array:
	var start_id = graph.get_closest_point(start)
	var end_id = graph.get_closest_point(end)
	
	if start_id == -1 or end_id == -1:
		print("No valid start or end point found")
		return []
		
	var id_path = graph.get_id_path(start_id, end_id)
	if id_path.is_empty():
		print("No path found between points")
		return []
	
	var actions = []
	var prev_tile = null
	
	for i in range(id_path.size()):
		var pid = id_path[i]
		var pos = graph.get_point_position(pid)
		var tile = pid_to_tile[pid]
		
		if prev_tile != null:
			var dx = tile.x - prev_tile.x
			var dy = tile.y - prev_tile.y
			
			# Check if we need to jump
			var need_jump = false
			
			# CASE 1: Horizontal gap - need jump when gap is 2 or more tiles
			if dy == 0 and abs(dx) >= 2:
				if abs(dx) <= jump_distance:
					# Check if theres a walkable path through adjacent tiles
					need_jump = true
					
					for step in range(1, abs(dx)):
						var check_x = prev_tile.x + step * sign(dx)
						var check_tile = Vector2i(check_x, prev_tile.y)
						
						# If theres a walkable tile in between, we dont need to jump
						if check_tile in tile_to_pid:
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
		
		actions.append(pos + Vector2(0, cell_size * 0.2))
		prev_tile = tile
	
	actions.append(end + Vector2(0, cell_size * 0.2))
	return actions


func create_map() -> void:
	# Create a point for every "walkable" tile
	var used = tile_map.get_used_cells()
	for c in used:
		var above = Vector2i(c.x, c.y - 1)
		if not above in used:
			addPointFor(c)


func addPointFor(tile_coords: Vector2i) -> void:
	var tile_above = Vector2i(tile_coords.x, tile_coords.y - 1)
	var local = tile_map.map_to_local(tile_above)
	var world = tile_map.to_global(local)
	
	var nearest = graph.get_closest_point(world)
	if nearest != -1 and graph.get_point_position(nearest).distance_to(world) < 0.1:
		return
		
	var pid = graph.get_available_point_id()
	graph.add_point(pid, world)
	tile_to_pid[tile_coords] = pid
	pid_to_tile[pid] = tile_coords
	
	if show_lines:
		var mark = MARKER.instantiate()
		mark.position = world + Vector2(0, cell_size * 0.2)
		call_deferred("add_child", mark)


func create_connections() -> void:
	var used_cells = tile_map.get_used_cells()
	
	var tile_grid = {}
	for tile_pos in tile_to_pid.keys():
		tile_grid[tile_pos] = tile_to_pid[tile_pos]
	
	for tile_pos in tile_to_pid.keys():
		var idA = tile_to_pid[tile_pos]
		
		# 1: Only check direct neighbors for walkable connections (±1 in X)
		for dx in [-1, 1]:
			var neighbor_pos = Vector2i(tile_pos.x + dx, tile_pos.y)
			if neighbor_pos in tile_grid:
				var idB = tile_grid[neighbor_pos]
				graph.connect_points(idA, idB)
		
		# 2: Only check specific positions for jump connections
		for jump_x in range(2, jump_distance + 1):
			for direction in [-1, 1]:
				var jump_pos = Vector2i(tile_pos.x + (jump_x * direction), tile_pos.y)
				
				# Only process if this jump destination exists
				if jump_pos in tile_grid:
					# Check if theres a walkable path instead
					var needs_jump = true
					for step in range(1, jump_x):
						var step_pos = Vector2i(tile_pos.x + (step * direction), tile_pos.y)
						if step_pos in tile_grid:
							needs_jump = false
							break
					
					if needs_jump:
						var idB = tile_grid[jump_pos]
						graph.connect_points(idA, idB)
		
		# 3: Diagonal jumps upward
		for jump_y in range(1, jump_height + 1):
			for jump_x in range(1, jump_distance + 1):
				for direction in [-1, 1]:
					var jump_pos = Vector2i(tile_pos.x + (jump_x * direction), tile_pos.y - jump_y)
					
					# Only process if this diagonal jump destination exists
					if jump_pos in tile_grid:
						# Check for clearance above the player
						var has_clearance = true
						for y_check in range(1, jump_y + 1):
							var check_pos = Vector2i(tile_pos.x, tile_pos.y - y_check)
							if check_pos in used_cells:
								has_clearance = false
								break
						
						if has_clearance and not is_blocked(tile_pos, jump_pos, used_cells):
							var idB = tile_grid[jump_pos]
							graph.connect_points(idA, idB)
		
		# 4: Diagonal movement downward
		for jump_y in range(1, jump_height + 1):
			for jump_x in range(1, jump_distance + 1):
				for direction in [-1, 1]:
					var jump_pos = Vector2i(tile_pos.x + (jump_x * direction), tile_pos.y + jump_y)
					
					# Only process if this diagonal down destination exists
					if jump_pos in tile_grid:
						# Check if were at an edge
						var edge_pos = Vector2i(tile_pos.x + direction, tile_pos.y)
						var at_edge = not edge_pos in used_cells
						
						if at_edge:
							# Check for a clear path
							var path_is_clear = true
							
							# Check if the tiles in between are clear
							for x_off in range(1, jump_x + 1):
								var x_pos = tile_pos.x + (x_off * direction)
								
								for y_off in range(0, jump_y):
									var check_pos = Vector2i(x_pos, tile_pos.y + y_off)
									if check_pos in used_cells:
										path_is_clear = false
										break
								
								if not path_is_clear:
									break
							
							if path_is_clear and has_space_for_drop(tile_pos, jump_pos, used_cells):
								var idB = tile_grid[jump_pos]
								graph.connect_points(idA, idB)
	
	# 5: Drop connections
	create_drop_connections(tile_grid, used_cells)


func create_drop_connections(tile_grid, used_cells) -> void:
	for tile_pos in tile_grid.keys():
		var idA = tile_grid[tile_pos]
		
		# Check both left and right for ledges
		for direction in [-1, 1]:
			var side_pos = Vector2i(tile_pos.x + direction, tile_pos.y)
			var above_side_pos = Vector2i(tile_pos.x + direction, tile_pos.y - 1)
			
			var is_ledge = not side_pos in used_cells and not above_side_pos in used_cells
			
			if is_ledge:
				find_drop_target(idA, tile_pos, direction, tile_grid, used_cells)


func find_drop_target(idA, tile_pos, direction, tile_grid, used_cells) -> void:
	var max_drop_distance = 3
	var max_drop_height = 10
	
	# First, find the highest, topmost, target at each X position
	var highest_targets = {}  # Store highest target by X position
	
	for drop_distance in range(1, max_drop_distance + 1):
		var target_x = tile_pos.x + (direction * drop_distance)
		
		for drop_height in range(1, max_drop_height + 1):
			var target_pos = Vector2i(target_x, tile_pos.y + drop_height)
			
			if target_pos in tile_grid:
				# If we havent found a target at this X yet, or if this one is higher (lower Y value)
				if not target_x in highest_targets or target_pos.y < highest_targets[target_x].y:
					highest_targets[target_x] = {
						"y": target_pos.y,
						"pos": target_pos,
						"id": tile_grid[target_pos]
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
		# Check the vertical drop path (not accurate for eg x distance 3, since it doesnt check the distance 2)
		for y in range(1, target.y - tile_pos.y):
			var check_pos = Vector2i(target.pos.x, tile_pos.y + y)
			if check_pos in used_cells:
				has_clearance = false
				break
		
		if has_clearance and not graph.are_points_connected(idA, idB):
			graph.connect_points(idA, idB, false)
			
			targets_found += 1
			if targets_found >= 3:
				return  # Limit to 3 connections per ledge direction

# Check if theres a block in the way for jumping
func is_blocked(from_tile: Vector2i, to_tile: Vector2i, used_cells) -> bool:
	# Calc jump arc and check for obstacles
	var dx = to_tile.x - from_tile.x
	var dy = to_tile.y - from_tile.y
	
	if dx == 0:
		# Vertical jump - check all points in between
		var y_step = sign(dy)
		for y in range(from_tile.y + y_step, to_tile.y, y_step):
			var check_tile = Vector2i(from_tile.x, y)
			if check_tile in used_cells:
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
		if check_tile in used_cells:
			return true
	
	return false


func has_space_for_drop(from_tile: Vector2i, to_tile: Vector2i, used_cells) -> bool:
	var dx = to_tile.x - from_tile.x
	
	# First, ensure theres actually a path to drop down
	# Check the entire column from starting height to landing height
	for y in range(from_tile.y + 1, to_tile.y):
		var check_tile = Vector2i(from_tile.x, y)
		if check_tile in used_cells:
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
					
				if check_tile in used_cells:
					return false
			
			# Check a fixed height (3 tiles) above this position for clearance
			for h in range(1, 4):
				var check_tile = Vector2i(x, from_tile.y - h)
				if check_tile in used_cells:
					return false
	
	return true


func _draw() -> void:
	if not show_lines:
		return
		
	var pts = graph.get_point_ids()
	for idA in pts:
		var pA = graph.get_point_position(idA)
		var tileA = pid_to_tile[idA]
		
		var connections = graph.get_point_connections(idA)
		for idB in connections:
			var pB = graph.get_point_position(idB)
			var tileB = pid_to_tile[idB]
			
			var dx = tileB.x - tileA.x
			var dy = tileB.y - tileA.y
			
			# Check if its a one-way connection (drop)
			var is_bidirectional = graph.are_points_connected(idB, idA)
			
			# Color scheme:
			# Blue: Adjacent walkable tiles (dx=1, same Y)
			# Red: Requires jump (horizontal gap or up)
			# Green: Walking down diagonally
			# Orange: One-way drop connection, probably all the time handled with green
			
			var color
			if not is_bidirectional:
				color = Color.ORANGE
			elif dy == 0 and abs(dx) == 1:
				color = Color.BLUE
			elif (dy == 0 and abs(dx) > 1) or dy < 0:
				color = Color.DARK_RED
			else:
				color = Color.GREEN
				
			draw_line(pA, pB, color, 1)
