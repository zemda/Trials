class_name VersionInfo
extends RefCounted

const VERSION = "v0.0.1"


static func get_version() -> String:
	return VERSION


static func get_full_version_string() -> String:
	var version = get_version()
	
	if OS.has_feature("debug"):
		version += " (Debug)"
	
	return version
