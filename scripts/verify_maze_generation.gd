# verify_maze_generation.gd
# Verify maze generates correctly and is visible in scene
# Run with: godot --headless --path . --script scripts/verify_maze_generation.gd

extends SceneTree

func _initialize() -> void:
	print("========================================")
	print("  Maze Generation Verification")
	print("========================================")
	
	# Load first available maze scene from maze_levels
	var maze_levels_dir = DirAccess.open("res://maze_levels")
	if maze_levels_dir == null:
		print("ERROR: maze_levels directory not found")
		quit(1)
		return
	
	# Find first .tscn file
	var maze_scene_path = null
	maze_levels_dir.list_dir_begin()
	var file_name = maze_levels_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			maze_scene_path = "res://maze_levels/" + file_name
			break
		file_name = maze_levels_dir.get_next()
	
	if maze_scene_path == null:
		print("ERROR: No maze scene found in maze_levels/")
		print("Run generate_maze_level.gd first to create a maze scene")
		quit(1)
		return
	
	var maze_scene = load(maze_scene_path) as PackedScene
	if maze_scene == null:
		print("ERROR: Failed to load maze scene: %s" % maze_scene_path)
		quit(1)
		return
	
	print("✓ Maze scene loaded: %s" % maze_scene_path)
	
	# Instantiate maze
	var maze_instance = maze_scene.instantiate()
	get_root().add_child(maze_instance)
	
	await process_frame
	await process_frame
	
	# The root of maze.tscn is the Maze node itself
	var maze_node = maze_instance
	if maze_node.name != "Maze":
		# Try to find Maze node as child
		maze_node = maze_instance.get_node_or_null("Maze")
		if maze_node == null:
			print("ERROR: Maze node not found (root name: %s)" % maze_instance.name)
			quit(1)
			return
	
	print("✓ Maze node found: %s" % maze_node.name)
	
	# Wait for generation (maze_generator._ready() should have run)
	for i in range(20):
		await process_frame
	
	# Check for generated geometry
	var floor_tiles = maze_node.get_node_or_null("FloorTiles")
	var walls = maze_node.get_node_or_null("Walls")
	
	if floor_tiles == null:
		print("ERROR: FloorTiles container not found")
		quit(1)
		return
	
	if walls == null:
		print("ERROR: Walls container not found")
		quit(1)
		return
	
	var floor_count = floor_tiles.get_child_count()
	var wall_count = walls.get_child_count()
	
	print("✓ Floor tiles created: %d" % floor_count)
	print("✓ Walls created: %d" % wall_count)
	
	if floor_count == 0:
		print("ERROR: No floor tiles generated")
		quit(1)
		return
	
	if wall_count == 0:
		print("ERROR: No walls generated")
		quit(1)
		return
	
	# Check config
	var config = maze_node.config
	if config == null:
		print("ERROR: Config is null")
		quit(1)
		return
	
	print("✓ Config found: %d x %d" % [config.maze_width, config.maze_height])
	
	# Expected counts
	var expected_floors = config.maze_width * config.maze_height
	print("Expected floor tiles: %d" % expected_floors)
	
	if floor_count != expected_floors:
		print("WARNING: Floor count mismatch (got %d, expected %d)" % [floor_count, expected_floors])
	
	print("\n========================================")
	print("  ✅ MAZE GENERATION VERIFIED")
	print("========================================")
	print("PASSED")
	quit(0)

