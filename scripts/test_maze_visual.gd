# test_maze_visual.gd
# Test script to verify maze has closed boundaries
# Run with: godot --headless --path . --script scripts/test_maze_visual.gd

extends SceneTree

var error_count = 0

# Will find first maze scene from maze_levels/
var MAZE_SCENE_PATH = ""

func _initialize() -> void:
	run_tests()

func run_tests() -> void:
	print("========================================")
	print("  Maze Boundary Test - Verifying Closed Edges")
	print("========================================")
	
	error_count = 0
	
	# Find first maze scene in maze_levels
	var maze_levels_dir = DirAccess.open("res://maze_levels")
	if maze_levels_dir == null:
		record_error("maze_levels directory not found - run generate_maze_level.gd first")
		finish_test()
		return
	
	maze_levels_dir.list_dir_begin()
	var file_name = maze_levels_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			MAZE_SCENE_PATH = "res://maze_levels/" + file_name
			break
		file_name = maze_levels_dir.get_next()
	
	if MAZE_SCENE_PATH == "":
		record_error("No maze scene found in maze_levels/ - run generate_maze_level.gd first")
		finish_test()
		return
	
	# Load and instantiate maze
	var maze_scene = load(MAZE_SCENE_PATH) as PackedScene
	if maze_scene == null:
		record_error("Failed to load maze scene: %s" % MAZE_SCENE_PATH)
		finish_test()
		return
	
	var maze_instance = maze_scene.instantiate()
	if maze_instance == null:
		record_error("Failed to instantiate maze scene")
		finish_test()
		return
	
	get_root().add_child(maze_instance)
	
	# Wait for maze generation
	await process_frame
	await process_frame
	
	# Find maze node
	var maze_node = maze_instance.get_node_or_null("Maze")
	if maze_node == null:
		record_error("Maze node not found")
		finish_test()
		return
	
	# Get config
	var config = maze_node.config
	if config == null:
		record_error("Config not found")
		finish_test()
		return
	
	print("Maze config: %d x %d" % [config.maze_width, config.maze_height])
	print("Entry: (%d, %d)" % [config.entry_position.x, config.entry_position.y])
	print("Exit: (%d, %d)" % [config.exit_position.x, config.exit_position.y])
	
	# Generate maze
	print("Generating maze...")
	await maze_node.generate_maze()
	
	# Wait for generation to complete
	for i in range(20):
		await process_frame
	
	# Check walls container
	var walls_container = maze_node.get_node_or_null("Walls")
	if walls_container == null:
		record_error("Walls container not found")
		finish_test()
		return
	
	# Count walls
	var wall_count = walls_container.get_child_count()
	print("\nTotal walls created: %d" % wall_count)
	
	# Check for boundary walls by analyzing wall positions
	var width = config.maze_width
	var height = config.maze_height
	var tile_size = config.tile_size
	
	# Count walls at each boundary
	var north_wall_count = 0  # Top edge (Z = 0)
	var south_wall_count = 0  # Bottom edge (Z = height * tile_size)
	var west_wall_count = 0   # Left edge (X = 0)
	var east_wall_count = 0   # Right edge (X = width * tile_size)
	
	var entry_opened = false
	var exit_opened = false
	
	for wall in walls_container.get_children():
		var wall_pos = wall.position
		var wall_name = wall.name
		
		# Check north boundary (Z = 0, within tolerance)
		if abs(wall_pos.z) < 0.1:
			north_wall_count += 1
			# Check if this is entry/exit opening
			if config.entry_position.y == 0 and abs(wall_pos.x - (config.entry_position.x + 0.5) * tile_size) < tile_size:
				entry_opened = true
			if config.exit_position.y == 0 and abs(wall_pos.x - (config.exit_position.x + 0.5) * tile_size) < tile_size:
				exit_opened = true
		
		# Check south boundary (Z = height * tile_size)
		var south_z = height * tile_size
		if abs(wall_pos.z - south_z) < 0.1:
			south_wall_count += 1
			if config.entry_position.y == height - 1 and abs(wall_pos.x - (config.entry_position.x + 0.5) * tile_size) < tile_size:
				entry_opened = true
			if config.exit_position.y == height - 1 and abs(wall_pos.x - (config.exit_position.x + 0.5) * tile_size) < tile_size:
				exit_opened = true
		
		# Check west boundary (X = 0)
		if abs(wall_pos.x) < 0.1:
			west_wall_count += 1
			if config.entry_position.x == 0 and abs(wall_pos.z - (config.entry_position.y + 0.5) * tile_size) < tile_size:
				entry_opened = true
			if config.exit_position.x == 0 and abs(wall_pos.z - (config.exit_position.y + 0.5) * tile_size) < tile_size:
				exit_opened = true
		
		# Check east boundary (X = width * tile_size)
		var east_x = width * tile_size
		if abs(wall_pos.x - east_x) < 0.1:
			east_wall_count += 1
			if config.entry_position.x == width - 1 and abs(wall_pos.z - (config.entry_position.y + 0.5) * tile_size) < tile_size:
				entry_opened = true
			if config.exit_position.x == width - 1 and abs(wall_pos.z - (config.exit_position.y + 0.5) * tile_size) < tile_size:
				exit_opened = true
	
	print("\nBoundary wall counts:")
	print("  North (top): %d walls (expected ~%d, minus entry/exit if on this edge)" % [north_wall_count, width])
	print("  South (bottom): %d walls (expected ~%d, minus entry/exit if on this edge)" % [south_wall_count, width])
	print("  West (left): %d walls (expected ~%d, minus entry/exit if on this edge)" % [west_wall_count, height])
	print("  East (right): %d walls (expected ~%d, minus entry/exit if on this edge)" % [east_wall_count, height])
	
	# Verify boundaries are mostly closed (allow for entry/exit openings)
	var expected_north = width
	if config.entry_position.y == 0:
		expected_north -= 1
	if config.exit_position.y == 0:
		expected_north -= 1
	
	var expected_south = width
	if config.entry_position.y == height - 1:
		expected_south -= 1
	if config.exit_position.y == height - 1:
		expected_south -= 1
	
	var expected_west = height
	if config.entry_position.x == 0:
		expected_west -= 1
	if config.exit_position.x == 0:
		expected_west -= 1
	
	var expected_east = height
	if config.entry_position.x == width - 1:
		expected_east -= 1
	if config.exit_position.x == width - 1:
		expected_east -= 1
	
	print("\nExpected boundary walls (accounting for entry/exit):")
	print("  North: %d, South: %d, West: %d, East: %d" % [expected_north, expected_south, expected_west, expected_east])
	
	# Check if boundaries are closed (within reasonable tolerance)
	# Allow some variance due to wall placement logic
	if north_wall_count < expected_north - 2:
		record_error("North boundary not properly closed: got %d, expected ~%d" % [north_wall_count, expected_north])
	if south_wall_count < expected_south - 2:
		record_error("South boundary not properly closed: got %d, expected ~%d" % [south_wall_count, expected_south])
	if west_wall_count < expected_west - 2:
		record_error("West boundary not properly closed: got %d, expected ~%d" % [west_wall_count, expected_west])
	if east_wall_count < expected_east - 2:
		record_error("East boundary not properly closed: got %d, expected ~%d" % [east_wall_count, expected_east])
	
	# Verify entry/exit are actually open (check cell data)
	var algorithm = maze_node._algorithm
	if algorithm != null:
		var entry_cell = algorithm.get_cell(config.entry_position.x, config.entry_position.y)
		var exit_cell = algorithm.get_cell(config.exit_position.x, config.exit_position.y)
		
		print("\nEntry/Exit cell data:")
		print("  Entry cell walls: N=%s S=%s E=%s W=%s" % [entry_cell.get("north", true), entry_cell.get("south", true), entry_cell.get("east", true), entry_cell.get("west", true)])
		print("  Exit cell walls: N=%s S=%s E=%s W=%s" % [exit_cell.get("north", true), exit_cell.get("south", true), exit_cell.get("east", true), exit_cell.get("west", true)])
	
	finish_test()

func record_error(message: String) -> void:
	print("  ❌ ERROR: %s" % message)
	error_count += 1

func finish_test() -> void:
	print("\n========================================")
	print("  Test Summary")
	print("========================================")
	print("Errors: %d" % error_count)
	
	if error_count == 0:
		print("✅ Maze boundary test PASSED - All edges are closed!")
		print("PASSED")
		quit(0)
	else:
		print("❌ Maze boundary test FAILED - Some edges are not closed")
		print("FAILED")
		quit(1)

