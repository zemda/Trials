extends Node

const LEVEL_TIME_LEADERBOARD_PREFIX = "level_time_"
const GAME_COMPLETION_LEADERBOARD = "game_completion_time"

signal leaderboard_updated(leaderboard_name)

var _skip_detection = false


func _ready():
	var init_timer = Timer.new()
	init_timer.wait_time = 1.5
	init_timer.one_shot = true
	init_timer.timeout.connect(_on_init_timer_timeout)
	add_child(init_timer)
	init_timer.start()


func _on_init_timer_timeout():
	if Talo.identity_check() == OK:
		call_deferred("_ensure_all_leaderboards_exist")


func _ensure_all_leaderboards_exist() -> void:
	_create_leaderboard_if_not_exists(GAME_COMPLETION_LEADERBOARD)
	
	_create_leaderboard_if_not_exists(LEVEL_TIME_LEADERBOARD_PREFIX + "Level01")
	_create_leaderboard_if_not_exists(LEVEL_TIME_LEADERBOARD_PREFIX + "Level02")
	_create_leaderboard_if_not_exists(LEVEL_TIME_LEADERBOARD_PREFIX + "Level03")


func _create_leaderboard_if_not_exists(leaderboard_name: String) -> void:
	var res = await Talo.leaderboards.get_entries(leaderboard_name, 0)
	if res.entries.size() == 0:
		var dummy_score = 999999.0
		await Talo.leaderboards.add_entry(leaderboard_name, dummy_score)


func set_skip_detection(skipped: bool) -> void:
	_skip_detection = skipped


func was_skipped() -> bool:
	return _skip_detection


func clear_skip_detection() -> void:
	_skip_detection = false


func submit_level_time(level_name: String, time_seconds: float) -> void:
	if _skip_detection:
		return
		
	if Talo.identity_check() != OK:
		return
	
	var simple_level_name = level_name.get_file().get_basename()
	if simple_level_name.is_empty():
		simple_level_name = level_name
	
	var leaderboard_name = LEVEL_TIME_LEADERBOARD_PREFIX + simple_level_name
	
	var res = await Talo.leaderboards.add_entry(leaderboard_name, time_seconds)
	
	emit_signal("leaderboard_updated", leaderboard_name)


func submit_game_time(time_seconds: float) -> void:
	if _skip_detection:
		return
		
	if Talo.identity_check() != OK:
		return
	
	var res = await Talo.leaderboards.add_entry(GAME_COMPLETION_LEADERBOARD, time_seconds)
	
	emit_signal("leaderboard_updated", GAME_COMPLETION_LEADERBOARD)


func get_all_leaderboards() -> Array:
	var leaderboards = []
	
	leaderboards.append({
		"name": "Game Completion Times",
		"id": GAME_COMPLETION_LEADERBOARD
	})
	
	leaderboards.append({
		"name": "Level01",
		"id": LEVEL_TIME_LEADERBOARD_PREFIX + "Level01"
	})
	
	leaderboards.append({
		"name": "Level02",
		"id": LEVEL_TIME_LEADERBOARD_PREFIX + "Level02"
	})
	
	leaderboards.append({
		"name": "Level03",
		"id": LEVEL_TIME_LEADERBOARD_PREFIX + "Level03"
	})
	
	return leaderboards
