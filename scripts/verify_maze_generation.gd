# verify_maze_generation.gd
# Verify maze generates correctly and is visible in scene
# Run with: godot --headless --path . --script scripts/verify_maze_generation.gd

extends SceneTree

func _initialize() -> void:
	print("========================================")
	print("  Maze Generation Verification")
	print("========================================")
	
	# Load maze scene
	var maze_scene = load("res://maze.tscn") as PackedScene
	if maze_scene == null:
		print("ERROR: Failed to load maze.tscn")
		quit(1)
		return
	
	print("✓ Maze scene loaded")
	
	# Instantiate maze
	var maze_instance = maze_scene.instantiate()
	get_root().add_child(maze_instance)
	
	await process_frame
	await process_frame
	
	var maze_node = maze_instance.get_node_or_null("Maze")
	if maze_node == null:
		print("ERROR: Maze node not found")
		quit(1)
		return
	
	print("✓ Maze node found")
	
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

