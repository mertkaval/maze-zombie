# test_runtime.gd
# Script to test scenes run without crashes
# Works in headless mode: godot --headless --path . --script scripts/test_runtime.gd

extends SceneTree

var error_count = 0
var test_count = 0

const MAIN_SCENE_PATH = "res://main.tscn"
const MAZE_SCENE_PATH = "res://maze.tscn"
const PLAYER_SCENE_PATH = "res://player.tscn"


func _initialize() -> void:
	print("========================================")
	print("  Runtime Tests")
	print("========================================")
	
	error_count = 0
	test_count = 0
	
	# Test 1: Load main scene
	test_load_main_scene()
	
	# Test 2: Verify scene tree structure
	test_scene_tree_structure()
	
	# Test 3: Check for missing dependencies
	test_missing_dependencies()
	
	# Test 4: Verify node validity
	test_node_validity()
	
	# Print summary
	print("\n========================================")
	print("  Test Summary")
	print("========================================")
	print("Tests run: %d" % test_count)
	print("Errors: %d" % error_count)
	
	if error_count == 0:
		print("✅ All runtime tests PASSED")
		print("PASSED")
		quit(0)
	else:
		print("❌ Runtime tests FAILED")
		print("FAILED")
		quit(1)


func test_load_main_scene() -> void:
	test_count += 1
	print("\n[Test %d] Loading main scene..." % test_count)
	
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		record_error("Main scene file does not exist: %s" % MAIN_SCENE_PATH)
		return
	
	var scene = load(MAIN_SCENE_PATH) as PackedScene
	if scene == null:
		record_error("Failed to load main scene")
		return
	
	print("  ✓ Main scene loaded successfully")
	
	# Try to instantiate
	var instance = scene.instantiate()
	if instance == null:
		record_error("Failed to instantiate main scene")
		return
	
	print("  ✓ Main scene instantiated successfully")
	instance.queue_free()


func test_scene_tree_structure() -> void:
	test_count += 1
	print("\n[Test %d] Testing scene tree structure..." % test_count)
	
	var scene = load(MAIN_SCENE_PATH) as PackedScene
	if scene == null:
		record_error("Cannot test structure - scene failed to load")
		return
	
	var instance = scene.instantiate()
	if instance == null:
		record_error("Failed to instantiate main scene")
		return
	
	# Check for required nodes
	var required_nodes = ["Main", "Sun", "WorldEnvironment", "Maze", "Player"]
	for node_name in required_nodes:
		var node = instance.get_node_or_null(node_name)
		if node == null:
			record_error("Required node not found in main scene: %s" % node_name)
		else:
			print("  ✓ Found node: %s (%s)" % [node_name, node.get_class()])
	
	# Check Sun is DirectionalLight3D
	var sun = instance.get_node_or_null("Sun")
	if sun != null:
		if sun.get_class() != "DirectionalLight3D":
			record_error("Sun node is not DirectionalLight3D, got: %s" % sun.get_class())
		else:
			print("  ✓ Sun is DirectionalLight3D")
	
	# Check WorldEnvironment
	var env = instance.get_node_or_null("WorldEnvironment")
	if env != null:
		if env.get_class() != "WorldEnvironment":
			record_error("WorldEnvironment node is wrong type, got: %s" % env.get_class())
		else:
			print("  ✓ WorldEnvironment node valid")
	
	# Check Maze instance
	var maze = instance.get_node_or_null("Maze")
	if maze != null:
		print("  ✓ Maze instance found")
		# Check if it has the generator script
		if maze.get_script() != null:
			print("  ✓ Maze has script attached")
		else:
			record_warning("Maze instance has no script")
	else:
		record_error("Maze instance not found")
	
	# Check Player instance
	var player = instance.get_node_or_null("Player")
	if player != null:
		print("  ✓ Player instance found")
		# Check for Camera3D
		var camera = player.get_node_or_null("Camera3D")
		if camera == null:
			record_error("Player missing Camera3D")
		else:
			print("  ✓ Player has Camera3D")
		
		# Check for CollisionShape3D
		var collision = player.get_node_or_null("CollisionShape3D")
		if collision == null:
			record_error("Player missing CollisionShape3D")
		else:
			print("  ✓ Player has CollisionShape3D")
	else:
		record_error("Player instance not found")
	
	instance.queue_free()


func test_missing_dependencies() -> void:
	test_count += 1
	print("\n[Test %d] Checking for missing dependencies..." % test_count)
	
	var scene = load(MAIN_SCENE_PATH) as PackedScene
	if scene == null:
		record_error("Cannot check dependencies - scene failed to load")
		return
	
	var instance = scene.instantiate()
	if instance == null:
		record_error("Failed to instantiate scene")
		return
	
	# Check if referenced scenes exist
	var maze_scene = load(MAZE_SCENE_PATH) as PackedScene
	if maze_scene == null:
		record_error("Maze scene dependency missing: %s" % MAZE_SCENE_PATH)
	else:
		print("  ✓ Maze scene dependency exists")
	
	var player_scene = load(PLAYER_SCENE_PATH) as PackedScene
	if player_scene == null:
		record_error("Player scene dependency missing: %s" % PLAYER_SCENE_PATH)
	else:
		print("  ✓ Player scene dependency exists")
	
	# Check prefabs
	var floor_prefab = load("res://floor_tile.tscn") as PackedScene
	if floor_prefab == null:
		record_error("Floor tile prefab missing")
	else:
		print("  ✓ Floor tile prefab exists")
	
	var wall_prefab = load("res://wall_tile.tscn") as PackedScene
	if wall_prefab == null:
		record_error("Wall tile prefab missing")
	else:
		print("  ✓ Wall tile prefab exists")
	
	instance.queue_free()


func test_node_validity() -> void:
	test_count += 1
	print("\n[Test %d] Testing node validity..." % test_count)
	
	var scene = load(MAIN_SCENE_PATH) as PackedScene
	if scene == null:
		record_error("Cannot test validity - scene failed to load")
		return
	
	var instance = scene.instantiate()
	if instance == null:
		record_error("Failed to instantiate scene")
		return
	
	# Recursively check all nodes
	check_node_validity(instance, "")
	
	instance.queue_free()


func check_node_validity(node: Node, path: String) -> void:
	var current_path = path + "/" + node.name if path != "" else node.name
	
	# Check if node is valid
	if not is_instance_valid(node):
		record_error("Invalid node at path: %s" % current_path)
		return
	
	# Check node properties
	if node.name.is_empty():
		record_warning("Node with empty name at path: %s" % current_path)
	
	# Recursively check children
	for child in node.get_children():
		check_node_validity(child, current_path)
	
	# Check specific node types
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh == null:
			record_warning("MeshInstance3D '%s' has no mesh" % current_path)
	
	if node is CollisionShape3D:
		var collision = node as CollisionShape3D
		if collision.shape == null:
			record_warning("CollisionShape3D '%s' has no shape" % current_path)
	
	if node is Camera3D:
		var camera = node as Camera3D
		if camera == null:
			record_warning("Camera3D '%s' is invalid" % current_path)


func record_error(message: String) -> void:
	var error_msg = "[ERROR] %s" % message
	print("  ❌ %s" % error_msg)
	error_count += 1


func record_warning(message: String) -> void:
	print("  ⚠️  [WARNING] %s" % message)
