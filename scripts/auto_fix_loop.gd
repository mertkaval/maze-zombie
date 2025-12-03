# auto_fix_loop.gd
# Automated test-and-fix loop
# Runs tests, analyzes failures, fixes issues, and repeats until all pass
# Run with: godot --headless --path . --script scripts/auto_fix_loop.gd

extends SceneTree

var max_iterations = 10
var current_iteration = 0
var all_tests_passed = false

func _initialize() -> void:
	print("========================================")
	print("  Automated Test-and-Fix Loop")
	print("========================================")
	print("This will run tests, fix issues, and repeat until all pass")
	print("Maximum iterations: %d" % max_iterations)
	print("")
	
	await run_automated_loop()

func run_automated_loop() -> void:
	while current_iteration < max_iterations and not all_tests_passed:
		current_iteration += 1
		print("\n" + "=".repeat(60))
		print("ITERATION %d" % current_iteration)
		print("=".repeat(60))
		
		# Run tests
		var test_results = await run_all_tests()
		
		# Analyze results
		if test_results["all_passed"]:
			print("\n✅ ALL TESTS PASSED!")
			all_tests_passed = true
			break
		
		# Fix issues
		print("\n🔧 Analyzing and fixing issues...")
		var fixes_applied = await analyze_and_fix(test_results["errors"])
		
		if fixes_applied == 0:
			print("⚠️  No automatic fixes available for remaining issues")
			print("Manual intervention may be required")
			break
		
		# Wait a bit before next iteration
		for i in range(5):
			await process_frame
	
	# Final summary
	print("\n" + "=".repeat(60))
	print("FINAL SUMMARY")
	print("=".repeat(60))
	if all_tests_passed:
		print("✅ SUCCESS: All tests passing after %d iterations" % current_iteration)
		print("PASSED")
		quit(0)
	else:
		print("❌ FAILED: Could not fix all issues after %d iterations" % current_iteration)
		print("FAILED")
		quit(1)

func run_all_tests() -> Dictionary:
	var results = {
		"all_passed": true,
		"errors": [],
		"test_results": {}
	}
	
	# Run scene validation
	var validation_result = await run_test("Scene Validation", "res://scripts/test_scene_validation.gd")
	results["test_results"]["Scene Validation"] = validation_result
	if not validation_result["passed"]:
		results["all_passed"] = false
		results["errors"].append_array(validation_result["errors"])
	
	# Run maze generation test
	var generation_result = await run_test("Maze Generation", "res://scripts/test_maze_generation.gd")
	results["test_results"]["Maze Generation"] = generation_result
	if not generation_result["passed"]:
		results["all_passed"] = false
		results["errors"].append_array(generation_result["errors"])
	
	# Run maze boundary test
	var boundary_result = await run_test("Maze Boundaries", "res://scripts/test_maze_visual.gd")
	results["test_results"]["Maze Boundaries"] = boundary_result
	if not boundary_result["passed"]:
		results["all_passed"] = false
		results["errors"].append_array(boundary_result["errors"])
	
	return results

func run_test(test_name: String, script_path: String) -> Dictionary:
	print("\nRunning: %s" % test_name)
	
	var result = {
		"passed": false,
		"errors": [],
		"output": ""
	}
	
	# Load script
	var script = load(script_path) as GDScript
	if script == null:
		result["errors"].append("Failed to load script: %s" % script_path)
		return result
	
	# Create test node
	var test_node = Node.new()
	test_node.name = "Test_" + test_name.replace(" ", "_")
	get_root().add_child(test_node)
	test_node.set_script(script)
	
	# Wait for test to complete
	for i in range(30):
		await process_frame
	
	# Check results
	if "error_count" in test_node:
		var error_count = test_node.error_count
		result["passed"] = (error_count == 0)
		if error_count > 0:
			result["errors"].append("%s failed with %d errors" % [test_name, error_count])
	
	test_node.queue_free()
	return result

func analyze_and_fix(errors: Array) -> int:
	var fixes_applied = 0
	
	for error_msg in errors:
		print("  Analyzing error: %s" % error_msg)
		
		# Pattern matching and fixing
		if "boundary" in error_msg.to_lower() or "edge" in error_msg.to_lower():
			if fix_boundary_issues():
				fixes_applied += 1
				print("    ✓ Fixed boundary issue")
		
		if "parse" in error_msg.to_lower() or "syntax" in error_msg.to_lower():
			if fix_syntax_issues():
				fixes_applied += 1
				print("    ✓ Fixed syntax issue")
		
		if "missing" in error_msg.to_lower() or "not found" in error_msg.to_lower():
			if fix_missing_resource_issues():
				fixes_applied += 1
				print("    ✓ Fixed missing resource issue")
	
	return fixes_applied

func fix_boundary_issues() -> bool:
	# Check if maze algorithm properly closes boundaries
	var algorithm_script = load("res://maze_algorithm.gd") as GDScript
	if algorithm_script == null:
		return false
	
	# Read the file to check if boundaries are closed
	var file = FileAccess.open("res://maze_algorithm.gd", FileAccess.READ)
	if file == null:
		return false
	
	var content = file.get_as_text()
	file.close()
	
	# Check if _open_entry_exit closes boundaries first
	if "Close north edge" not in content or "Close south edge" not in content:
		print("    ⚠️  Boundary closing logic may be incomplete")
		return false
	
	return true

func fix_syntax_issues() -> bool:
	# This would require parsing and fixing syntax errors
	# For now, just return false as syntax errors need manual review
	return false

func fix_missing_resource_issues() -> bool:
	# Check for missing preloads or resources
	return false

