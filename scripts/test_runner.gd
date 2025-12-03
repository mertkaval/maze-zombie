# test_runner.gd
# Main test runner that executes all tests
# Run with: godot --headless --path . test_runner.tscn

extends Node

var all_passed = true
var test_results = {}

func _ready() -> void:
	print("========================================")
	print("  Test Runner - Executing All Tests")
	print("========================================")
	
	# Run all tests by loading and executing scripts
	run_test_script("Scene Validation", "res://scripts/test_scene_validation.gd")
	run_test_script("Maze Generation", "res://scripts/test_maze_generation.gd")
	run_test_script("Runtime", "res://scripts/test_runtime.gd")
	run_test_script("Scene Analysis", "res://scripts/analyze_scenes.gd")
	
	# Final result
	print("\n========================================")
	print("  Final Result")
	print("========================================")
	if all_passed:
		print("✅ ALL TESTS PASSED")
		print("PASSED")
		get_tree().quit(0)
	else:
		print("❌ SOME TESTS FAILED")
		print("FAILED")
		get_tree().quit(1)


func run_test_script(test_name: String, script_path: String) -> void:
	print("\n" + "=" * 50)
	print("Running: %s" % test_name)
	print("=" * 50)
	
	# Load the script
	var script = load(script_path) as GDScript
	if script == null:
		print("❌ Failed to load script: %s" % script_path)
		all_passed = false
		test_results[test_name] = "FAILED_TO_LOAD"
		return
	
	# Create a temporary node to run the test
	var test_node = Node.new()
	test_node.name = "TestNode_" + test_name.replace(" ", "_")
	add_child(test_node)
	
	# Set the script on the node
	test_node.set_script(script)
	
	# Call run_tests if it exists
	if test_node.has_method("run_tests"):
		test_node.run_tests()
		var passed = not test_node.has_method("get_error_count") or test_node.get_error_count() == 0
		test_results[test_name] = "PASSED" if passed else "FAILED"
		if not passed:
			all_passed = false
	else:
		print("⚠️  Script does not have run_tests() method")
		test_results[test_name] = "NO_METHOD"
	
	# Clean up
	test_node.queue_free()

