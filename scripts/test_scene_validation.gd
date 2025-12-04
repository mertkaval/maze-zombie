# test_scene_validation.gd
# Script to validate all scenes can load and have correct structure
# Works in headless mode: godot --headless --path . --script scripts/test_scene_validation.gd

extends Node

var test_results = []
var error_count = 0
var warning_count = 0

func _ready() -> void:
	run_tests()
	# Don't quit here - let the test runner handle it

# Scene paths to test
const SCENES_TO_TEST = {
		# "maze.tscn": {  # Removed - using maze_levels/ instead
		"maze_levels": {
		"required_nodes": ["Maze"],
		"required_script": "maze_generator.gd",
		"node_type": "Node3D"
	},
	"main.tscn": {
		"required_nodes": ["Main", "Sun", "WorldEnvironment", "Maze", "Player"],
		"node_type": "Node3D"
	},
	"player.tscn": {
		"required_nodes": ["Player", "CollisionShape3D", "Camera3D"],
		"required_script": "player_controller.gd",
		"node_type": "CharacterBody3D"
	},
	"floor_tile.tscn": {
		"required_nodes": ["FloorTile", "MeshInstance3D", "CollisionShape3D"],
		"node_type": "StaticBody3D"
	},
	"wall_tile.tscn": {
		"required_nodes": ["WallTile", "MeshInstance3D", "CollisionShape3D"],
		"node_type": "StaticBody3D"
	}
}


func run_tests() -> void:
	print("========================================")
	print("  Scene Validation Tests")
	print("========================================")
	
	test_results.clear()
	error_count = 0
	warning_count = 0
	
	# Test each scene
	for scene_path in SCENES_TO_TEST.keys():
		test_scene(scene_path, SCENES_TO_TEST[scene_path])
	
	# Print summary
	print("\n========================================")
	print("  Test Summary")
	print("========================================")
	print("Total scenes tested: %d" % SCENES_TO_TEST.size())
	print("Errors: %d" % error_count)
	print("Warnings: %d" % warning_count)
	
	if error_count == 0:
		print("✅ All scene validation tests PASSED")
		print("PASSED")
	else:
		print("❌ Scene validation tests FAILED")
		print("FAILED")


func test_scene(scene_path: String, requirements: Dictionary) -> void:
	print("\n[Test] Testing scene: %s" % scene_path)
	
	var full_path = "res://" + scene_path
	
	# Check if file exists
	if not ResourceLoader.exists(full_path):
		record_error(scene_path, "Scene file does not exist: %s" % full_path)
		return
	
	# Load the scene
	var scene = load(full_path) as PackedScene
	if scene == null:
		record_error(scene_path, "Failed to load scene as PackedScene")
		return
	
	print("  ✓ Scene loaded successfully")
	
	# Instantiate the scene
	var instance = scene.instantiate()
	if instance == null:
		record_error(scene_path, "Failed to instantiate scene")
		return
	
	print("  ✓ Scene instantiated successfully")
	
	# Check root node type
	if requirements.has("node_type"):
		var expected_type = requirements["node_type"]
		if instance.get_class() != expected_type:
			record_error(scene_path, "Root node type mismatch. Expected: %s, Got: %s" % [expected_type, instance.get_class()])
		else:
			print("  ✓ Root node type correct: %s" % expected_type)
	
	# Check required nodes
	if requirements.has("required_nodes"):
		for node_name in requirements["required_nodes"]:
			var node = null
			# First check if it's the root node itself
			if instance.name == node_name:
				node = instance
			else:
				# Check direct children
				node = instance.get_node_or_null(node_name)
				if node == null:
					# Try finding by name recursively
					node = instance.find_child(node_name, true, false)
			
			if node == null:
				record_error(scene_path, "Required node not found: %s" % node_name)
			else:
				print("  ✓ Found node: %s" % node_name)
	
	# Check required script
	if requirements.has("required_script"):
		var script_path = "res://" + requirements["required_script"]
		if instance.get_script() == null:
			record_error(scene_path, "Required script not attached: %s" % requirements["required_script"])
		else:
			var script_resource = instance.get_script()
			if script_resource is GDScript:
				var script_path_actual = (script_resource as GDScript).resource_path
				if script_path_actual != script_path and not script_path_actual.ends_with(requirements["required_script"]):
					record_warning(scene_path, "Script path mismatch. Expected: %s, Got: %s" % [script_path, script_path_actual])
				else:
					print("  ✓ Script attached correctly: %s" % requirements["required_script"])
	
	# Check for missing resources
	check_missing_resources(instance, scene_path)
	
	# Clean up
	instance.queue_free()
	
	print("  ✓ Scene validation complete: %s" % scene_path)


func check_missing_resources(node: Node, scene_path: String) -> void:
	# Check MeshInstance3D nodes for missing meshes
	for mesh_instance in node.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh == null:
			record_error(scene_path, "MeshInstance3D '%s' has no mesh assigned" % mesh_instance.get_path())
	
	# Check CollisionShape3D nodes for missing shapes
	for collision_shape in node.find_children("*", "CollisionShape3D", true, false):
		if collision_shape.shape == null:
			record_error(scene_path, "CollisionShape3D '%s' has no shape assigned" % collision_shape.get_path())
	
	# Check Camera3D nodes
	for camera in node.find_children("*", "Camera3D", true, false):
		if camera == null:
			record_warning(scene_path, "Camera3D node found but invalid")
	
	# Check for materials
	for mesh_instance in node.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh != null:
			var mesh = mesh_instance.mesh
			if mesh is ArrayMesh:
				var array_mesh = mesh as ArrayMesh
				if array_mesh.get_surface_count() > 0:
					var material = array_mesh.surface_get_material(0)
					if material == null:
						record_warning(scene_path, "MeshInstance3D '%s' has no material" % mesh_instance.get_path())


func record_error(scene_path: String, message: String) -> void:
	var error_msg = "[ERROR] %s: %s" % [scene_path, message]
	print("  ❌ %s" % error_msg)
	test_results.append(error_msg)
	error_count += 1


func record_warning(scene_path: String, message: String) -> void:
	var warning_msg = "[WARNING] %s: %s" % [scene_path, message]
	print("  ⚠️  %s" % warning_msg)
	test_results.append(warning_msg)
	warning_count += 1
