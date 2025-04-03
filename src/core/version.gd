class_name Version
extends RefCounted

const VERSION_FILE = "res://version.txt"


static func get_version() -> String:
	if FileAccess.file_exists(VERSION_FILE):
		var file = FileAccess.open(VERSION_FILE, FileAccess.READ)
		var version = file.get_as_text().strip_edges()
		file.close()
		return version
	else:
		return "v0.0.1"


static func get_full_version_string() -> String:
	var version = get_version()
	
	if OS.has_feature("debug"):
		version += " (Debug)"
	
	return version
