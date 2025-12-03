# run_test.gd
# Standalone test runner that can be executed with --script
# Usage: godot --headless --path . --script scripts/run_test.gd test_name
# Example: godot --headless --path . --script scripts/run_test.gd validation

extends SceneTree

var test_name = ""

func _initialize() -> void:
	# Get test name from command line arguments
	var args = OS.get_cmdline_args()
	if args.size() > 0:
		# Find --script argument and get the next one as test name
		for i in range(args.size()):
			if args[i] == "--script" and i + 1 < args.size():
				# The script path is args[i+1], test name might be after
				if i + 2 < args.size():
					test_name = args[i + 2]
					break
	
	# If no test name provided, run all tests
	if test_name == "":
		run_all_tests()
	else:
		run_specific_test(test_name)
	
	quit(0)


func run_all_tests() -> void:
	print("========================================")
	print("  Running All Tests")
	print("========================================")
	
	# Create a temporary scene tree to run Node-based tests
	var test_root = Node.new()
	test_root.name = "TestRoot"
	get_root().add_child(test_root)
	
	# Run each test
	run_test_script(test_root, "Scene Validation", load("res://scripts/test_scene_validation.gd"))
	run_test_script(test_root, "Maze Generation", load("res://scripts/test_maze_generation.gd"))
	run_test_script(test_root, "Runtime", load("res://scripts/test_runtime.gd"))
	run_test_script(test_root, "Scene Analysis", load("res://scripts/analyze_scenes.gd"))
	
	# Clean up
	test_root.queue_free()


func run_specific_test(test: String) -> void:
	print("Running test: %s" % test)
	
	var test_root = Node.new()
	test_root.name = "TestRoot"
	get_root().add_child(test_root)
	
	match test:
		"validation":
			run_test_script(test_root, "Scene Validation", load("res://scripts/test_scene_validation.gd"))
		"generation":
			run_test_script(test_root, "Maze Generation", load("res://scripts/test_maze_generation.gd"))
		"runtime":
			run_test_script(test_root, "Runtime", load("res://scripts/test_runtime.gd"))
		"analysis":
			run_test_script(test_root, "Scene Analysis", load("res://scripts/analyze_scenes.gd"))
		_:
			print("Unknown test: %s" % test)
	
	test_root.queue_free()


func run_test_script(parent: Node, test_name_param: String, script: GDScript) -> void:
	if script == null:
		print("❌ Failed to load script for: %s" % test_name_param)
		return

	print("\n" + "=".repeat(50))
	print("Running: %s" % test_name_param)
	print("=".repeat(50))

	var test_node = Node.new()
	test_node.name = "Test_" + test_name_param.replace(" ", "_")
	parent.add_child(test_node)
	test_node.set_script(script)

	# Wait a frame for _ready to execute
	# SceneTree IS the tree, so use process_frame directly
	await process_frame
	
	test_node.queue_free()

