# get_maze_scene_path.gd
# Helper function to get first maze scene from maze_levels folder
# Returns path to first .tscn file found, or null if none exists

static func get_first_maze_scene() -> String:
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

