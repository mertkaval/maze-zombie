# verify_maze_bounds.gd
# Detailed verification of maze boundaries
# Run with: godot --headless --path . --script scripts/verify_maze_bounds.gd

extends SceneTree

func _initialize() -> void:
	print("========================================")
	print("  Maze Boundary Verification")
	print("========================================")
	
	# Load and generate maze
	var maze_scene = load("res://maze.tscn") as PackedScene
	if maze_scene == null:
		print("ERROR: Failed to load maze scene")
		quit(1)
		return
	
	var maze_instance = maze_scene.instantiate()
	get_root().add_child(maze_instance)
	
	await process_frame
	await process_frame
	
	var maze_node = maze_instance.get_node_or_null("Maze")
	if maze_node == null:
		print("ERROR: Maze node not found")
		quit(1)
		return
	
	var config = maze_node.config
	if config == null:
		print("ERROR: Config not found")
		quit(1)
		return
	
	# Generate maze
	await maze_node.generate_maze()
	
	# Wait for generation
	for i in range(20):
		await process_frame
	
	# Get algorithm to check cell data
	var algorithm = maze_node._algorithm
	if algorithm == null:
		print("ERROR: Algorithm not found")
		quit(1)
		return
	
	var width = config.maze_width
	var height = config.maze_height
	
	print("\nChecking boundary cell walls:")
	print("Entry: (%d, %d)" % [config.entry_position.x, config.entry_position.y])
	print("Exit: (%d, %d)" % [config.exit_position.x, config.exit_position.y])
	
	# Check north boundary (top row, y=0)
	print("\nNorth boundary (top row, y=0):")
	var north_closed_count = 0
	for x in range(width):
		var cell = algorithm.get_cell(x, 0)
		if cell.get("north", false):
			north_closed_count += 1
		else:
			print("  Opening at x=%d (entry/exit?)" % x)
	print("  Closed: %d/%d cells" % [north_closed_count, width])
	
	# Check south boundary (bottom row, y=height-1)
	print("\nSouth boundary (bottom row, y=%d):" % (height - 1))
	var south_closed_count = 0
	for x in range(width):
		var cell = algorithm.get_cell(x, height - 1)
		if cell.get("south", false):
			south_closed_count += 1
		else:
			print("  Opening at x=%d (entry/exit?)" % x)
	print("  Closed: %d/%d cells" % [south_closed_count, width])
	
	# Check west boundary (left column, x=0)
	print("\nWest boundary (left column, x=0):")
	var west_closed_count = 0
	for y in range(height):
		var cell = algorithm.get_cell(0, y)
		if cell.get("west", false):
			west_closed_count += 1
		else:
			print("  Opening at y=%d (entry/exit?)" % y)
	print("  Closed: %d/%d cells" % [west_closed_count, height])
	
	# Check east boundary (right column, x=width-1)
	print("\nEast boundary (right column, x=%d):" % (width - 1))
	var east_closed_count = 0
	for y in range(height):
		var cell = algorithm.get_cell(width - 1, y)
		if cell.get("east", false):
			east_closed_count += 1
		else:
			print("  Opening at y=%d (entry/exit?)" % y)
	print("  Closed: %d/%d cells" % [east_closed_count, height])
	
	# Verify entry/exit are open
	var entry_cell = algorithm.get_cell(config.entry_position.x, config.entry_position.y)
	var exit_cell = algorithm.get_cell(config.exit_position.x, config.exit_position.y)
	
	print("\nEntry cell (%d, %d) walls:" % [config.entry_position.x, config.entry_position.y])
	print("  N=%s S=%s E=%s W=%s" % [entry_cell.get("north", true), entry_cell.get("south", true), entry_cell.get("east", true), entry_cell.get("west", true)])
	
	print("\nExit cell (%d, %d) walls:" % [config.exit_position.x, config.exit_position.y])
	print("  N=%s S=%s E=%s W=%s" % [exit_cell.get("north", true), exit_cell.get("south", true), exit_cell.get("east", true), exit_cell.get("west", true)])
	
	# Summary
	var expected_north = width - (1 if config.entry_position.y == 0 else 0) - (1 if config.exit_position.y == 0 else 0)
	var expected_south = width - (1 if config.entry_position.y == height - 1 else 0) - (1 if config.exit_position.y == height - 1 else 0)
	var expected_west = height - (1 if config.entry_position.x == 0 else 0) - (1 if config.exit_position.x == 0 else 0)
	var expected_east = height - (1 if config.entry_position.x == width - 1 else 0) - (1 if config.exit_position.x == width - 1 else 0)
	
	print("\n========================================")
	print("  Summary")
	print("========================================")
	print("North: %d/%d closed (expected %d)" % [north_closed_count, width, expected_north])
	print("South: %d/%d closed (expected %d)" % [south_closed_count, width, expected_south])
	print("West: %d/%d closed (expected %d)" % [west_closed_count, height, expected_west])
	print("East: %d/%d closed (expected %d)" % [east_closed_count, height, expected_east])
	
	var all_ok = (north_closed_count == expected_north and 
	              south_closed_count == expected_south and
	              west_closed_count == expected_west and
	              east_closed_count == expected_east)
	
	if all_ok:
		print("\n✅ All boundaries properly closed!")
		print("PASSED")
		quit(0)
	else:
		print("\n❌ Boundary closure mismatch!")
		print("FAILED")
		quit(1)

