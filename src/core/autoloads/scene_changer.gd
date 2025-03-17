extends Node

signal scene_loaded

@export var max_load_time = 10000 # 10 seconds max loading time

var _is_changing_scene: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func goto_scene(path: String) -> void:
	print("SceneChanger: Changing to scene: ", path)
	
	if _is_changing_scene:
		return
		
	_is_changing_scene = true
	var error = ResourceLoader.load_threaded_request(path)
	
	if error != OK:
		print("SceneChanger: unable to load, error code: ", error)
		_is_changing_scene = false
		return
	
	LoadingScreen.show_loading_screen()
	var current_scene = get_tree().current_scene
	var t = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < max_load_time:
		var progress_array = []
		var status = ResourceLoader.load_threaded_get_status(path, progress_array)
		match status:
			0, 2: # THREAD_LOAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
				LoadingScreen.hide_loading_screen()
				_is_changing_scene = false
				break
			1: # THREAD_LOAD_IN_PROGRESS
				var progress = progress_array[0] if progress_array.size() > 0 else 0.0
				LoadingScreen.update_progress(progress)
			3: # THREAD_LOAD_LOADED
				var resource = ResourceLoader.load_threaded_get(path)
				var new_scene = resource.instantiate()
				
				get_tree().root.call_deferred("add_child", new_scene)
				await get_tree().process_frame
				get_tree().current_scene = new_scene
				
				if current_scene:
					current_scene.queue_free()
				
				LoadingScreen.hide_loading_screen()
				
				_is_changing_scene = false
				emit_signal("scene_loaded")
				break
		
		await get_tree().process_frame
	
	if _is_changing_scene:
		LoadingScreen.hide_loading_screen()
		_is_changing_scene = false
