# maze_scene_helper.gd
# Helper functions for finding maze scenes in maze_levels folder

static func find_first_maze_scene() -> String:
	"""Returns path to first .tscn file in maze_levels/, or empty string if none found"""
	var maze_levels_dir = DirAccess.open("res://maze_levels")
	if maze_levels_dir == null:
		return ""
	
	maze_levels_dir.list_dir_begin()
	var file_name = maze_levels_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			return "res://maze_levels/" + file_name
		file_name = maze_levels_dir.get_next()
	
	return ""

static func ensure_maze_levels_exists() -> bool:
	"""Ensures maze_levels directory exists, returns true if successful"""
	if not DirAccess.dir_exists_absolute("res://maze_levels"):
		var dir = DirAccess.open("res://")
		if dir == null:
			return false
		var result = dir.make_dir("maze_levels")
		return result == OK
	return true

