# test_maze_visual.gd
# Test script to verify maze has closed boundaries
# Run with: godot --headless --path . --script scripts/test_maze_visual.gd

extends Node

var error_count = 0

const MAZE_SCENE_PATH = "res://maze.tscn"

func _ready() -> void:
	run_tests()

func run_tests() -> void:
	print("========================================")
	print("  Maze Boundary Test")
	print("========================================")
	
	error_count = 0
	
	# Load and instantiate maze
	var maze_scene = load(MAZE_SCENE_PATH) as PackedScene
	if maze_scene == null:
		record_error("Failed to load maze scene")
		finish_test()
		return
	
	var maze_instance = maze_scene.instantiate()
	if maze_instance == null:
		record_error("Failed to instantiate maze scene")
		finish_test()
		return
	
	add_child(maze_instance)
	
	# Wait for maze generation
	await get_tree().process_frame
	await get_tree().process_frame
	
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
	
	# Generate maze
	await maze_node.generate_maze()
	
	# Wait for generation to complete
	for i in range(10):
		await get_tree().process_frame
	
	# Check walls container
	var walls_container = maze_node.get_node_or_null("Walls")
	if walls_container == null:
		record_error("Walls container not found")
		finish_test()
		return
	
	# Count walls
	var wall_count = walls_container.get_child_count()
	print("Total walls created: %d" % wall_count)
	
	# Check for boundary walls
	var has_north_walls = false
	var has_south_walls = false
	var has_east_walls = false
	var has_west_walls = false
	
	for wall in walls_container.get_children():
		var wall_name = wall.name
		if "Wall_N_" in wall_name and wall_name.contains("_0_"):
			has_north_walls = true
		if "Wall_S_" in wall_name:
			has_south_walls = true
		if "Wall_E_" in wall_name:
			has_east_walls = true
		if "Wall_W_" in wall_name and wall_name.contains("_0"):
			has_west_walls = true
	
	print("Boundary check:")
	print("  North walls: %s" % ("✓" if has_north_walls else "✗"))
	print("  South walls: %s" % ("✓" if has_south_walls else "✗"))
	print("  East walls: %s" % ("✓" if has_east_walls else "✗"))
	print("  West walls: %s" % ("✓" if has_west_walls else "✗"))
	
	if not has_north_walls:
		record_error("North boundary walls missing")
	if not has_south_walls:
		record_error("South boundary walls missing")
	if not has_east_walls:
		record_error("East boundary walls missing")
	if not has_west_walls:
		record_error("West boundary walls missing")
	
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
		print("✅ Maze boundary test PASSED")
		print("PASSED")
		get_tree().quit(0)
	else:
		print("❌ Maze boundary test FAILED")
		print("FAILED")
		get_tree().quit(1)

