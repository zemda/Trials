extends Node

const LEVEL_TIME_LEADERBOARD_PREFIX = "level_time_"
const GAME_COMPLETION_LEADERBOARD = "game_completion_time"

signal leaderboard_updated(leaderboard_name)

func _ready():
	var init_timer = Timer.new()
	init_timer.wait_time = 1.5
	init_timer.one_shot = true
	init_timer.timeout.connect(_on_init_timer_timeout)
	add_child(init_timer)
	init_timer.start()


func _on_init_timer_timeout():
	if Talo.identity_check() == OK:
		print("LeaderboardManager: Player authenticated and ready to submit scores")
	else:
		print("LeaderboardManager: Player not yet authenticated")


func submit_level_time(level_name: String, time_seconds: float) -> void:
	if Talo.identity_check() != OK:
		return
	
	var simple_level_name = level_name.get_file().get_basename()
	if simple_level_name.is_empty():
		simple_level_name = level_name
	
	var leaderboard_name = LEVEL_TIME_LEADERBOARD_PREFIX + simple_level_name
	var res = await Talo.leaderboards.add_entry(leaderboard_name, time_seconds)
	print("LeaderboardManager: Submitted level time %s for %s, updated: %s" % [time_seconds, simple_level_name, res.updated])
	
	emit_signal("leaderboard_updated", leaderboard_name)


func submit_game_time(time_seconds: float) -> void:
	if Talo.identity_check() != OK:
		return
	
	var res = await Talo.leaderboards.add_entry(GAME_COMPLETION_LEADERBOARD, time_seconds)
	print("LeaderboardManager: Submitted game time %s, updated: %s" % [time_seconds, res.updated])
	
	emit_signal("leaderboard_updated", GAME_COMPLETION_LEADERBOARD)
