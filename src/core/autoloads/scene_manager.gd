extends Node

const LoadingScreenPath = "res://ui/loading_screen/LoadingScreen.tscn"
const PauseScreenPath = "res://ui/pause_screen/PauseScreen.tscn"
const PlayerPath = "res://nodes/player/player.tscn"
const Level01Path= "res://levels/level01/Level01.tscn"
const StartScreenPath = "res://ui/start_screen/StartScreen.tscn"
const EndScreenPath = "res://ui/end_screen/EndScreen.tscn"

func get_loading_screen_instance() -> Node:
	return load(LoadingScreenPath).instantiate()


func get_pause_screen_instance() -> Node:
	return load(PauseScreenPath).instantiate()


func get_player_instance() -> Node:
	return load(PlayerPath).instantiate()
