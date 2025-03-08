extends CharacterBody2D

var last_target_position = Vector2.ZERO
var current_trajectory = {"arc": -1, "points": []}
var has_trajectory = false

func _process(_delta):
	if Input.is_action_just_pressed("grapple"):
		var target_position = get_global_mouse_position()
		last_target_position = target_position
		current_trajectory = find_valid_trajectory(target_position)
		has_trajectory = true
		queue_redraw()

func check_collision(pos_: Vector2) -> bool:
	var tilemap = $"../Map/base"
	for x in range(0, 7):
		for y in range(0, 7):
			var pos = pos_ + Vector2(x, y)
			var map_pos = tilemap.local_to_map(pos)
			if tilemap.get_cell_source_id(map_pos) != -1:
				print(map_pos)
				return true
	return false

func find_valid_trajectory(target_position: Vector2) -> Dictionary:
	print("finding")
	var gravity = 2000
	var valid_arc = -1
	var valid_points = []
	
	for arc in range(1, 151):
		var arc_height = target_position.y - global_position.y - arc
		arc_height = min(-arc, arc_height)
		
		var velocity = _get_arc_velocity(global_position, target_position, arc_height, gravity, gravity)
		
		if velocity == Vector2.ZERO:
			continue
		
		var points = []
		var pos = global_position
		var current_velocity = velocity
		var time_step = 0.001
		var max_steps = 100000
		var hit_obstacle = false
		var reached_target = false
		
		points.append(pos)
		for i in range(max_steps):
			pos += current_velocity * time_step
			points.append(pos)
			
			if check_collision(pos):
				hit_obstacle = true
				break
			
			if pos.distance_to(target_position) < 5: # rng
				reached_target = true
				break
			
			current_velocity.y += gravity * time_step
		
		if not hit_obstacle and reached_target:
			valid_arc = arc
			valid_points = points
			print("valid arc: ", valid_arc)
			break
	
	return {"arc": valid_arc, "points": valid_points}

func _draw():
	if has_trajectory:
		var valid_arc = current_trajectory["arc"]
		var trajectory_points = current_trajectory["points"]
		
		if valid_arc > 0:
			for i in range(1, trajectory_points.size()):
				var start_point = to_local(trajectory_points[i-1])
				var end_point = to_local(trajectory_points[i])
				
				draw_line(start_point, end_point, Color.GREEN, 2)
			
			draw_circle(to_local(last_target_position), 5, Color.RED)
		else:
			draw_circle(to_local(last_target_position), 5, Color.RED)

func _get_arc_velocity(point_a: Vector2, point_b: Vector2, arc_height: float, up_gravity: float, down_gravity: float) -> Vector2:
	
	var velocity := Vector2.ZERO
	var displacement = point_b - point_a
	
	if displacement.y > arc_height:
		var time_up = sqrt(-2 * arc_height / float(up_gravity))
		var time_down = sqrt(2 * (displacement.y - arc_height) / float(down_gravity))
		
		velocity.y = -sqrt(-2 * up_gravity * arc_height)
		velocity.x = displacement.x / float(time_up + time_down)
	
	return velocity
