extends Node

signal scene_loaded
signal progress_changed(value)

@export var max_load_time = 10000 # 10 seconds max loading time

var _is_changing_scene: bool = false
var _loading_screen = null


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func goto_scene(path):
	print("SceneChanger: Changing to scene: ", path)
	
	if _is_changing_scene:
		return
		
	_is_changing_scene = true
	var error = ResourceLoader.load_threaded_request(path)
	
	if error != OK:
		print("SceneChanger: unable to load, error code: ", error)
		_is_changing_scene = false
		return
	
	_create_loading_screen()
	GameManager.disable_player_input()
	var current_scene = get_tree().current_scene
	
	var t = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < max_load_time:
		var status = ResourceLoader.load_threaded_get_status(path)
		match status:
			0, 2: # THREAD_LOAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
				print("SceneChanger: Error while loading file")
				_clean_loading_screen()
				_is_changing_scene = false
				break
			1: # THREAD_LOAD_IN_PROGRESS
				var progress_array = []
				ResourceLoader.load_threaded_get_status(path, progress_array)
				var progress = progress_array[0] if progress_array.size() > 0 else 0.0
				emit_signal("progress_changed", progress)
			3: # THREAD_LOAD_LOADED
				var resource = ResourceLoader.load_threaded_get(path)
				var new_scene = resource.instantiate()
				
				get_tree().root.call_deferred("add_child", new_scene)
				await get_tree().process_frame
				get_tree().current_scene = new_scene
				
				if current_scene:
					current_scene.queue_free()
				
				_clean_loading_screen()
				GameManager.enable_player_input()
				
				_is_changing_scene = false
				emit_signal("scene_loaded")
				break
		
		await get_tree().process_frame
	
	if _is_changing_scene:
		print("SceneChanger: timedout")
		_clean_loading_screen()
		_is_changing_scene = false


func _create_loading_screen() -> void:
	var existing_screens = get_tree().get_nodes_in_group("loading_screen")
	for screen in existing_screens:
		if is_instance_valid(screen):
			screen.queue_free()
	
	var _loading = SceneManager.get_loading_screen_instance()
	if _loading:
		get_tree().root.call_deferred("add_child", _loading)
		_loading_screen = _loading
		
		await get_tree().process_frame
		_loading_screen.show_loading_screen()


func _clean_loading_screen() -> void:
	if _loading_screen and is_instance_valid(_loading_screen):
		_loading_screen.hide_loading_screen()
		await get_tree().create_timer(0.3).timeout
		_loading_screen.queue_free()
		_loading_screen = null
