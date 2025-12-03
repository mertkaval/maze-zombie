# test_all.gd
# Standalone test runner that works with --script flag
# Run with: godot --headless --path . --script scripts/test_all.gd

extends SceneTree

var total_errors = 0
var total_warnings = 0

func _initialize() -> void:
	print("========================================")
	print("  Running All Tests")
	print("========================================")
	
	# Create a root node to attach test scripts to
	var test_root = Node.new()
	test_root.name = "TestRoot"
	get_root().add_child(test_root)

	# Run each test
	var validation_errors = await run_test("Scene Validation", "res://scripts/test_scene_validation.gd", test_root)
	var generation_errors = await run_test("Maze Generation", "res://scripts/test_maze_generation.gd", test_root)
	var runtime_errors = await run_test("Runtime", "res://scripts/test_runtime.gd", test_root)
	var analysis_errors = await run_test("Scene Analysis", "res://scripts/analyze_scenes.gd", test_root)

	total_errors = validation_errors + generation_errors + runtime_errors + analysis_errors
	
	# Final summary
	print("\n" + "=".repeat(50))
	print("  FINAL TEST SUMMARY")
	print("=".repeat(50))
	print("Total errors: %d" % total_errors)
	print("Total warnings: %d" % total_warnings)
	
	if total_errors == 0:
		print("✅ ALL TESTS PASSED")
		print("PASSED")
		quit(0)
	else:
		print("❌ SOME TESTS FAILED")
		print("FAILED")
		quit(1)
	
	test_root.queue_free()


func run_test(test_name: String, script_path: String, parent: Node) -> int:
	print("\n" + "=".repeat(50))
	print("Running: %s" % test_name)
	print("=".repeat(50))
	
	var script = load(script_path) as GDScript
	if script == null:
		print("❌ Failed to load script: %s" % script_path)
		return 1
	
	var test_node = Node.new()
	test_node.name = "Test_" + test_name.replace(" ", "_")
	parent.add_child(test_node)
	test_node.set_script(script)
	
	# Process a few frames to let _ready execute
	for i in range(10):
		await process_frame
	
	# Get error count if available
	var errors = 0
	if test_node.has_method("get_error_count"):
		errors = test_node.get_error_count()
	elif "error_count" in test_node:
		errors = test_node.error_count
	
	test_node.queue_free()
	return errors

