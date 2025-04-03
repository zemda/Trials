extends Node

const SAVE_FILE: String = "user://talo_player.cfg"
const ENCRYPTION_KEY: String = "VeLiCeTaJnE_analytic$ h3sl0, n1k0mu h0 nerik3jte pls..."


func _ready():
	var init_timer = Timer.new()
	init_timer.wait_time = 0.5
	init_timer.one_shot = true
	init_timer.timeout.connect(_on_init_timer_timeout)
	add_child(init_timer)
	init_timer.start()


func _on_init_timer_timeout():
	var credentials = _load_credentials()
	
	if credentials.has("identifier") and credentials.has("password"):
		_login_player(credentials.identifier, credentials.password)
	else:
		_register_new_player()


func _register_new_player():
	var timestamp = Time.get_unix_time_from_system()
	var random_part = randi() % 1000000
	var identifier = "anon_" + str(timestamp) + "_" + str(random_part)
	var password = _generate_random_password(12)
	
	var error = await Talo.player_auth.register(identifier, password)
	
	if error == OK:
		print("Talo player registered successfully")
		_save_credentials(identifier, password)
		_ensure_socket_connected()
	else:
		push_error("Failed to register Talo player: " + str(Talo.player_auth.last_error))


func _login_player(identifier: String, password: String):
	var result = await Talo.player_auth.login(identifier, password)
	
	if result == Talo.player_auth.LoginResult.OK:
		print("Talo player logged in successfully")
		_ensure_socket_connected()
	else:
		push_error("Failed to login Talo player")
		_register_new_player()


func _ensure_socket_connected():
	if Talo.socket._socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		print("Opening socket connection for player presence")
		Talo.socket.open_connection()


func _generate_random_password(length: int) -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+"
	var password = ""
	for i in range(length):
		password += chars[randi() % chars.length()]
	return password


func _save_credentials(identifier: String, password: String):
	var config = ConfigFile.new()
	config.set_value("player", "identifier", identifier)
	config.set_value("player", "password", password)
	
	config.save_encrypted_pass(SAVE_FILE, ENCRYPTION_KEY)


func _load_credentials() -> Dictionary:
	var config = ConfigFile.new()
	
	if FileAccess.file_exists(SAVE_FILE):
		var error = config.load_encrypted_pass(SAVE_FILE, ENCRYPTION_KEY)
		
		if error == OK:
			return {
				"identifier": config.get_value("player", "identifier", ""),
				"password": config.get_value("player", "password", "")
			}
	
	return {}

# === TRACKING METHODS === 

func track_level_completed(level_name: String, time_seconds: float) -> void:
	Talo.events.track("level_completed", {
		"level_name": level_name,
		"time_seconds": time_seconds
	})


func track_player_death(level_name: String, death_position: Vector2) -> void:
	Talo.events.track("player_died", {
		"level_name": level_name,
		"position_x": death_position.x,
		"position_y": death_position.y,
		"time_in_level": GameManager.get_level_time()
	})


func track_level_time(level_name: String, time_seconds: float, is_new_best: bool) -> void:
	Talo.events.track("level_best_time", {
		"level_name": level_name,
		"time_seconds": time_seconds,
		"is_new_best": is_new_best
	})


func track_game_completed(total_time_seconds: float, is_new_best: bool) -> void:
	Talo.events.track("game_completed", {
		"total_time_seconds": total_time_seconds,
		"is_new_best": is_new_best
	})
