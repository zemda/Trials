extends MasterChain

const MINIMUM_DISTANCE = 8
const REST_CHECK_DELAY = 7

var _player: CharacterBody2D = null
var _player_in_range := false
var _linked := false
var _player_detected_segments_cnt := 0
var _attached_segment_index := -1
var _attaching_to_rope := false


func _ready() -> void:
	create_chain(false)
	_connect_segment_signals_to_rope()


func _physics_process(delta: float) -> void:
	if _attaching_to_rope:
		_attach_to_rope(delta)
		return
	
	if _linked:
		_handle_rope_swing_input()
		_handle_rope_climb_input()
		
		if Input.is_action_just_pressed("jump_off_rope"):
			_unlink_player_from_rope()
		
	elif _player_in_range:
		if Input.is_action_just_pressed("attach_rope"): # TODO should be handled in player files, so we can adjust from which state he can attach etc... _player_in_range -> rope_in_range in players script, if input in player script/states, then transition to rope state and call this link, ez
			_link_player_to_rope()


func _attach_to_rope(delta: float) -> void:
	var attached_segment = segments[_attached_segment_index]
	var target_position = attached_segment.global_position + Vector2(0, 15)
	var distance_to_target = _player.global_position.distance_to(target_position)
	
	var direction_to_target = (target_position - _player.global_position).normalized()
	var max_force = 100000
	var force = direction_to_target * min(distance_to_target * 500, max_force)
	_player.velocity += force * delta
	_player.velocity *= pow(0.5, delta * 60)

	if distance_to_target < 2:
		_player.global_position = target_position
		_player.velocity = Vector2.ZERO
		_attaching_to_rope = false


func _connect_segment_signals_to_rope() -> void:
	for segment in segments:
		segment.player_entered_segment.connect(_on_segment_player_entered)
		segment.player_exited_segment.connect(_on_segment_player_exited)


func _link_player_to_rope() -> void:
	_attached_segment_index = _find_closest_valid_segment()
	
	if _attached_segment_index != -1:
		_player.is_attached_to_rope = true
		_linked = true
		_attaching_to_rope = true
		_apply_initial_attach_boost()


func _unlink_player_from_rope() -> void:
	_linked = false
	_player.is_attached_to_rope = false
	
	var attached_segment = segments[_attached_segment_index]
	var boost = Vector2(attached_segment.linear_velocity.x * 2, -370)
	_attached_segment_index = -1

	boost.x = clamp(boost.x, -370, 350)
	if not _player.jump_sound.is_playing():
		_player.jump_sound.play()
	_player.velocity = Vector2.ZERO
	_player.velocity += boost


func _find_closest_valid_segment() -> int:
	if segments.size() <= 1:
		return -1

	var closest_distance = INF
	var closest_index = -1

	for segment_index in range(2, segments.size()):
		var segment = segments[segment_index]
		var distance = segment.global_position.distance_to(_player.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_index = segment_index

	return closest_index


func _handle_rope_swing_input() -> void:
	if _attached_segment_index == -1:
		return
	var attached_segment = segments[_attached_segment_index]
	_player.global_position = attached_segment.global_position + Vector2(0,15)
	
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis != 0:
		var swing_force = Vector2(input_axis * 500, 0)
		attached_segment.apply_central_force(swing_force)


func _handle_rope_climb_input() -> void: # TODO: add some timer, but then improve animation to be smooth
	if _attached_segment_index == -1 or not _player:
		return

	var up_down = Input.get_axis("climb_rope_up", "climb_rope_down")
	_climb_to_segment(_attached_segment_index + 1 * up_down)


func _climb_to_segment(new_index: int) -> void:
	if new_index < 2 or new_index >= segments.size():
		return
	var seg = segments[new_index]
	if not seg:
		return
	_attached_segment_index = new_index


func _apply_initial_attach_boost() -> void:
	var attached_segment = segments[_attached_segment_index]
	if attached_segment:
		var pos = Vector2(_player.velocity.normalized().x, 0)
		var force = Vector2(_player.velocity.x * 2, 0)
		attached_segment.apply_impulse(force, pos)


func _on_segment_player_entered(player_body: Node) -> void:
	if player_body.is_in_group("Player"):
		_player_detected_segments_cnt += 1
		_player_in_range = true
		_player = player_body


func _on_segment_player_exited(player_body: Node) -> void:
	if player_body.is_in_group("Player"):
		_player_detected_segments_cnt -= 1
		if _player_detected_segments_cnt == 0:
			_player_in_range = false
