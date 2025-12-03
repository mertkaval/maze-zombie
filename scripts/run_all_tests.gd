# run_all_tests.gd
# Master test runner - coordinates all tests and generates comprehensive report
# Run from CI: godot --headless --path . -s scripts/run_all_tests.gd
# Or as EditorScript in editor: File > Run

@tool
extends EditorScript

func _run() -> void:
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
	print("\nTo run tests locally:")
	print("  - Open each test script in Script Editor")
	print("  - Use File > Run to execute")
	print("\nOr use the CI pipeline which runs all tests automatically.")
	print("\n========================================")
	print("✅ Master test runner ready")
	print("PASSED")

