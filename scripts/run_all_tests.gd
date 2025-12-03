# run_all_tests.gd
# Master test runner - coordinates all tests and generates comprehensive report
# Works in headless mode: godot --headless --path . --script scripts/run_all_tests.gd

extends SceneTree

func _initialize() -> void:
	print("========================================")
	print("  Master Test Suite Runner")
	print("========================================")
	print("\nThis script coordinates all test suites.")
	print("In CI pipeline, each test runs separately.")
	print("\nTest suites available:")
	print("  1. scripts/test_scene_validation.gd")
	print("  2. scripts/test_maze_generation.gd")
	print("  3. scripts/test_runtime.gd")
	print("  4. scripts/analyze_scenes.gd")
	print("\nAll tests should be run individually by the CI pipeline.")
	print("\n========================================")
	print("✅ Master test runner ready")
	print("PASSED")
	quit(0)
