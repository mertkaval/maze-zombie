# generate_maze_level.gd
# EditorScript to generate new maze scenes dynamically
# Run this script from: Tools > Run Script
# Each run creates a new maze scene in maze_levels/ folder
# Naming: maze_01.tscn, maze_02.tscn, maze_03.tscn, etc.

@tool
extends EditorScript

# Preload for headless mode compatibility
const MazeConfig = preload("res://maze_config.gd")
const MazeAlgorithm = preload("res://maze_algorithm.gd")
const MazeBuilder = preload("res://maze_builder.gd")

## Base path for maze levels
const MAZE_LEVELS_PATH = "res://maze_levels/"


func _run() -> void:
	print("========================================")
	print("  Generate New Maze Level")
	print("========================================")
	
	# Ensure maze_levels directory exists
	if not DirAccess.dir_exists_absolute("res://maze_levels"):
		DirAccess.make_dir_recursive_absolute("res://maze_levels")
		print("[EditorScript] Created maze_levels directory")
	
	# Find next available maze number (maze_01, maze_02, etc.)
	var next_number = _find_next_maze_number()
	var level_name = "maze_%02d.tscn" % next_number
	var level_path = MAZE_LEVELS_PATH + level_name
	
	print("[EditorScript] Generating new maze level: %s" % level_name)
	
	# Create config with defaults
	var config = MazeConfig.create_default()
	print("[EditorScript] Config: %d x %d" % [config.maze_width, config.maze_height])
	
	# Create the maze node
	var maze_node = Node3D.new()
	maze_node.name = "Maze"
	
	# Attach maze_generator script
	var generator_script = load("res://maze_generator.gd")
	if generator_script == null:
		push_error("[EditorScript] Failed to load maze_generator.gd!")
		return
	
	maze_node.set_script(generator_script)
	maze_node.config = config
	
	# Add to editor scene tree temporarily so generation can work
	# EditorScript needs nodes in scene tree for proper execution
	var temp_parent = Node3D.new()
	temp_parent.name = "TempMazeParent"
	EditorInterface.get_edited_scene_root().add_child(temp_parent)
	temp_parent.add_child(maze_node)
	maze_node.owner = temp_parent
	
	# Generate the maze synchronously
	print("[EditorScript] Generating maze...")
	maze_node.generate_maze()
	
	# Wait for generation to complete (process frames)
	for i in range(50):
		await Engine.get_main_loop().process_frame
	
	# Verify generation worked
	var floor_tiles = maze_node.get_node_or_null("FloorTiles")
	var walls = maze_node.get_node_or_null("Walls")
	
	if floor_tiles == null or walls == null:
		push_error("[EditorScript] Maze generation failed - nodes not found!")
		temp_parent.queue_free()
		return
	
	var floor_count = floor_tiles.get_child_count()
	var wall_count = walls.get_child_count()
	
	print("[EditorScript] Generated:")
	print("  Floor tiles: %d" % floor_count)
	print("  Walls: %d" % wall_count)
	
	if floor_count == 0:
		push_error("[EditorScript] No floor tiles generated!")
		temp_parent.queue_free()
		return
	
	# Remove from temporary parent
	temp_parent.remove_child(maze_node)
	temp_parent.queue_free()
	
	# Set owners for all nodes (required for packing)
	# The Maze node will be the root of the saved scene
	_set_owners_recursive(maze_node, maze_node)
	
	# Pack the scene
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(maze_node)
	if result != OK:
		push_error("[EditorScript] Failed to pack scene! Error code: %d" % result)
		maze_node.queue_free()
		return
	
	# Save the scene
	print("[EditorScript] Saving scene to: %s" % level_path)
	var save_result = ResourceSaver.save(packed_scene, level_path)
	if save_result != OK:
		push_error("[EditorScript] Failed to save scene! Error code: %d" % save_result)
		maze_node.queue_free()
		return
	
	print("[EditorScript] Scene saved successfully!")
	print("[EditorScript] Maze level created: %s" % level_path)
	print("========================================")
	
	# Refresh file system
	EditorInterface.get_resource_filesystem().update_file(level_path)
	
	# Clean up
	maze_node.queue_free()
	
	print("\n[EditorScript] Done! New maze level created: %s" % level_name)


func _find_next_maze_number() -> int:
	# Find the highest existing maze number and return next
	var dir = DirAccess.open(MAZE_LEVELS_PATH)
	if dir == null:
		return 1
	
	var max_number = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.begins_with("maze_") and file_name.ends_with(".tscn"):
			# Extract number from filename (maze_01.tscn -> 1)
			var number_str = file_name.trim_prefix("maze_").trim_suffix(".tscn")
			var number = number_str.to_int()
			if number > max_number:
				max_number = number
		file_name = dir.get_next()
	
	return max_number + 1


func _set_owners_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_set_owners_recursive(child, owner)
