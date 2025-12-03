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
	
	# Run all tests by loading and executing scripts (async)
	await run_all_tests_async()
	
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


func run_all_tests_async() -> void:
	# Run all tests sequentially, awaiting each one
	await run_test_script("Scene Validation", "res://scripts/test_scene_validation.gd")
	await run_test_script("Maze Generation", "res://scripts/test_maze_generation.gd")
	await run_test_script("Runtime", "res://scripts/test_runtime.gd")
	await run_test_script("Scene Analysis", "res://scripts/analyze_scenes.gd")


func run_test_script(test_name: String, script_path: String) -> void:
	print("\n" + "=".repeat(50))
	print("Running: %s" % test_name)
	print("=".repeat(50))
	
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
	
	# Wait for _ready to execute (which calls run_tests)
	# Wait multiple frames to ensure async operations complete (like maze generation)
	for i in range(20):
		await get_tree().process_frame
	
	# Check error count
	var errors = 0
	if "error_count" in test_node:
		errors = test_node.error_count
	
	var passed = errors == 0
	test_results[test_name] = "PASSED" if passed else "FAILED"
	if not passed:
		all_passed = false
		print("  ❌ Test failed with %d errors" % errors)
	else:
		print("  ✅ Test passed")
	
	# Clean up
	test_node.queue_free()

