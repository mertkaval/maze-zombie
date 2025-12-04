# test_maze_generation.gd
# Script to test maze generation works correctly
# Works in headless mode: godot --headless --path . --script scripts/test_maze_generation.gd

extends Node

var error_count = 0
var test_count = 0

# Will find first maze scene from maze_levels/
var MAZE_SCENE_PATH = ""
const EXPECTED_FLOOR_COUNT = 40 * 40  # 40x40 tiles

func _ready() -> void:
	run_tests()
	# Don't quit here - let the test runner handle it

func run_tests() -> void:
	print("========================================")
	print("  Maze Generation Tests")
	print("========================================")
	
	error_count = 0
	test_count = 0
	
	# Find first maze scene
	MAZE_SCENE_PATH = MazeSceneHelper.find_first_maze_scene()
	if MAZE_SCENE_PATH == "":
		record_error("No maze scene found in maze_levels/ - run generate_maze_level.gd first")
		finish_test()
		return
	
	print("Using maze scene: %s" % MAZE_SCENE_PATH)
	
	# Test 1: Load maze scene
	test_load_maze_scene()
	
	# Test 2: Generate maze
	test_generate_maze()
	
	# Test 3: Verify structure
	test_maze_structure()
	
	# Test 4: Test with different seeds
	test_different_seeds()
	
	# Print summary
	print("\n========================================")
	print("  Test Summary")
	print("========================================")
	print("Tests run: %d" % test_count)
	print("Errors: %d" % error_count)
	
	if error_count == 0:
		print("✅ All maze generation tests PASSED")
		print("PASSED")
	else:
		print("❌ Maze generation tests FAILED")
		print("FAILED")


func test_load_maze_scene() -> void:
	test_count += 1
	print("\n[Test %d] Loading maze scene..." % test_count)
	
	if MAZE_SCENE_PATH == "":
		record_error("No maze scene found in maze_levels/ - run generate_maze_level.gd first")
		return
	
	if not ResourceLoader.exists(MAZE_SCENE_PATH):
		record_error("Maze scene file does not exist: %s" % MAZE_SCENE_PATH)
		return
	
	var scene = load(MAZE_SCENE_PATH) as PackedScene
	if scene == null:
		record_error("Failed to load maze scene: %s" % MAZE_SCENE_PATH)
		return
	
	print("  ✓ Maze scene loaded successfully: %s" % MAZE_SCENE_PATH)


func test_generate_maze() -> void:
	test_count += 1
	print("\n[Test %d] Testing maze generation..." % test_count)
	
	# Load and instantiate scene
	var scene = load(MAZE_SCENE_PATH) as PackedScene
	if scene == null:
		record_error("Cannot test generation - scene failed to load")
		return
	
	var instance = scene.instantiate()
	if instance == null:
		record_error("Failed to instantiate maze scene")
		return
	
	# Add to scene tree so generate_maze() can work properly
	var root = get_tree().get_root()
	root.add_child(instance)
	
	# Find Maze node
	var maze_node = instance
	if maze_node.name != "Maze":
		maze_node = instance.get_node_or_null("Maze")
		if maze_node == null:
			record_error("Could not find Maze node")
			instance.queue_free()
			return
	
	# Check if generate_maze method exists
	if not maze_node.has_method("generate_maze"):
		record_error("Maze node does not have generate_maze() method")
		instance.queue_free()
		return
	
	print("  ✓ Maze node found with generate_maze() method")
	
	# Call generate_maze() (async function)
	print("  Calling generate_maze()...")
	await maze_node.generate_maze()
	
	# Wait additional frames to ensure all nodes are added
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("  ✓ Maze generation completed")
	
	# Check for FloorTiles container
	var floor_tiles = maze_node.get_node_or_null("FloorTiles")
	if floor_tiles == null:
		record_error("FloorTiles container not found after generation")
	else:
		var floor_count = floor_tiles.get_child_count()
		print("  ✓ FloorTiles container found with %d children" % floor_count)
		
		if floor_count != EXPECTED_FLOOR_COUNT:
			record_error("Floor count mismatch. Expected: %d, Got: %d" % [EXPECTED_FLOOR_COUNT, floor_count])
		else:
			print("  ✓ Floor count correct: %d" % floor_count)
	
	# Check for Walls container
	var walls = maze_node.get_node_or_null("Walls")
	if walls == null:
		record_error("Walls container not found after generation")
	else:
		var wall_count = walls.get_child_count()
		print("  ✓ Walls container found with %d children" % wall_count)
		
		if wall_count == 0:
			record_error("No walls generated!")
		else:
			print("  ✓ Wall count: %d (reasonable)" % wall_count)
	
	# Clean up
	instance.queue_free()


func test_maze_structure() -> void:
	test_count += 1
	print("\n[Test %d] Testing maze structure..." % test_count)
	
	var scene = load(MAZE_SCENE_PATH) as PackedScene
	if scene == null:
		record_error("Cannot test structure - scene failed to load")
		return
	
	var instance = scene.instantiate()
	if instance == null:
		record_error("Failed to instantiate maze scene")
		return
	
	# Add to scene tree
	var root = get_tree().get_root()
	root.add_child(instance)
	
	var maze_node = instance
	if maze_node.name != "Maze":
		maze_node = instance.get_node_or_null("Maze")
	
	if maze_node == null:
		record_error("Could not find Maze node")
		instance.queue_free()
		return
	
	# Generate maze (async function)
	await maze_node.generate_maze()
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check floor tiles have proper structure
	var floor_tiles = maze_node.get_node_or_null("FloorTiles")
	if floor_tiles != null:
		var floor_sample = floor_tiles.get_child(0)
		if floor_sample != null:
			# Check it's a StaticBody3D
			if floor_sample.get_class() != "StaticBody3D":
				record_error("Floor tile is not StaticBody3D, got: %s" % floor_sample.get_class())
			else:
				print("  ✓ Floor tiles are StaticBody3D")
			
			# Check for MeshInstance3D
			var mesh_instance = floor_sample.get_node_or_null("MeshInstance3D")
			if mesh_instance == null:
				record_error("Floor tile missing MeshInstance3D")
			else:
				print("  ✓ Floor tiles have MeshInstance3D")
			
			# Check for CollisionShape3D
			var collision = floor_sample.get_node_or_null("CollisionShape3D")
			if collision == null:
				record_error("Floor tile missing CollisionShape3D")
			else:
				print("  ✓ Floor tiles have CollisionShape3D")
	
	# Check walls have proper structure
	var walls = maze_node.get_node_or_null("Walls")
	if walls != null and walls.get_child_count() > 0:
		var wall_sample = walls.get_child(0)
		if wall_sample != null:
			# Check it's a StaticBody3D
			if wall_sample.get_class() != "StaticBody3D":
				record_error("Wall tile is not StaticBody3D, got: %s" % wall_sample.get_class())
			else:
				print("  ✓ Wall tiles are StaticBody3D")
			
			# Check for MeshInstance3D
			var mesh_instance = wall_sample.get_node_or_null("MeshInstance3D")
			if mesh_instance == null:
				record_error("Wall tile missing MeshInstance3D")
			else:
				print("  ✓ Wall tiles have MeshInstance3D")
			
			# Check for CollisionShape3D
			var collision = wall_sample.get_node_or_null("CollisionShape3D")
			if collision == null:
				record_error("Wall tile missing CollisionShape3D")
			else:
				print("  ✓ Wall tiles have CollisionShape3D")
	
	instance.queue_free()


func test_different_seeds() -> void:
	test_count += 1
	print("\n[Test %d] Testing maze generation with different seeds..." % test_count)
	
	var scene = load(MAZE_SCENE_PATH) as PackedScene
	if scene == null:
		record_error("Cannot test seeds - scene failed to load")
		return
	
	var root = get_tree().get_root()
	
	# Test with seed 1
	var instance1 = scene.instantiate()
	root.add_child(instance1)
	var maze_node1 = instance1 if instance1.name == "Maze" else instance1.get_node_or_null("Maze")
	if maze_node1 != null and maze_node1.has_method("regenerate_with_seed"):
		maze_node1.regenerate_with_seed(1)
		# regenerate_with_seed calls generate_maze() which is async, wait for completion
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		var walls1 = maze_node1.get_node_or_null("Walls")
		var wall_count1 = walls1.get_child_count() if walls1 != null else 0
		print("  ✓ Generated with seed 1: %d walls" % wall_count1)
	instance1.queue_free()
	
	# Test with seed 42
	var instance2 = scene.instantiate()
	root.add_child(instance2)
	var maze_node2 = instance2 if instance2.name == "Maze" else instance2.get_node_or_null("Maze")
	if maze_node2 != null and maze_node2.has_method("regenerate_with_seed"):
		maze_node2.regenerate_with_seed(42)
		# regenerate_with_seed calls generate_maze() which is async, wait for completion
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		var walls2 = maze_node2.get_node_or_null("Walls")
		var wall_count2 = walls2.get_child_count() if walls2 != null else 0
		print("  ✓ Generated with seed 42: %d walls" % wall_count2)
	instance2.queue_free()
	
	print("  ✓ Seed testing completed")


func record_error(message: String) -> void:
	var error_msg = "[ERROR] %s" % message
	print("  ❌ %s" % error_msg)
	error_count += 1
