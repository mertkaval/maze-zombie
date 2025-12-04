# generate_maze_level_standalone.gd
# Standalone script to generate maze scenes (can run with --script)
# Run with: godot --headless --path . --script scripts/generate_maze_level_standalone.gd
# Or from editor: Tools > Run Script

@tool
extends SceneTree

const MazeConfig = preload("res://maze_config.gd")
const MazeAlgorithm = preload("res://maze_algorithm.gd")
const MazeBuilder = preload("res://maze_builder.gd")

const MAZE_LEVELS_PATH = "res://maze_levels/"


func _initialize() -> void:
	print("========================================")
	print("  Generate New Maze Level")
	print("========================================")
	
	# Ensure maze_levels directory exists
	if not DirAccess.dir_exists_absolute("res://maze_levels"):
		DirAccess.make_dir_recursive_absolute("res://maze_levels")
		print("[Script] Created maze_levels directory")
	
	# Find next available maze number
	var next_number = _find_next_maze_number()
	var level_name = "maze_%02d.tscn" % next_number
	var level_path = MAZE_LEVELS_PATH + level_name
	
	print("[Script] Generating new maze level: %s" % level_name)
	
	# Create config with defaults
	var config = MazeConfig.create_default()
	print("[Script] Config: %d x %d" % [config.maze_width, config.maze_height])
	
	# Create the maze node
	var maze_node = Node3D.new()
	maze_node.name = "Maze"
	
	# Attach maze_generator script
	var generator_script = load("res://maze_generator.gd")
	if generator_script == null:
		print("ERROR: Failed to load maze_generator.gd!")
		quit(1)
		return
	
	maze_node.set_script(generator_script)
	maze_node.config = config
	
	# Add to scene tree so generation can work
	get_root().add_child(maze_node)
	maze_node.owner = get_root()
	
	# Wait a frame for node to be ready
	await process_frame
	
	# Generate the maze
	print("[Script] Generating maze...")
	maze_node.generate_maze()
	
	# Wait for generation to complete
	for i in range(50):
		await process_frame
	
	# Verify generation worked
	var floor_tiles = maze_node.get_node_or_null("FloorTiles")
	var walls = maze_node.get_node_or_null("Walls")
	
	if floor_tiles == null or walls == null:
		print("ERROR: Maze generation failed - nodes not found!")
		quit(1)
		return
	
	var floor_count = floor_tiles.get_child_count()
	var wall_count = walls.get_child_count()
	
	print("[Script] Generated:")
	print("  Floor tiles: %d" % floor_count)
	print("  Walls: %d" % wall_count)
	
	if floor_count == 0:
		print("ERROR: No floor tiles generated!")
		quit(1)
		return
	
	# Remove from scene tree
	get_root().remove_child(maze_node)
	
	# Set owners for all nodes (required for packing)
	_set_owners_recursive(maze_node, maze_node)
	
	# Pack the scene
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(maze_node)
	if result != OK:
		print("ERROR: Failed to pack scene! Error code: %d" % result)
		maze_node.queue_free()
		quit(1)
		return
	
	# Save the scene
	print("[Script] Saving scene to: %s" % level_path)
	var save_result = ResourceSaver.save(packed_scene, level_path)
	if save_result != OK:
		print("ERROR: Failed to save scene! Error code: %d" % save_result)
		maze_node.queue_free()
		quit(1)
		return
	
	print("[Script] Scene saved successfully!")
	print("[Script] Maze level created: %s" % level_path)
	print("========================================")
	
	# Clean up
	maze_node.queue_free()
	
	print("\n[Script] Done! New maze level created: %s" % level_name)
	quit(0)


func _find_next_maze_number() -> int:
	var dir = DirAccess.open(MAZE_LEVELS_PATH)
	if dir == null:
		return 1
	
	var max_number = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.begins_with("maze_") and file_name.ends_with(".tscn"):
			var number_str = file_name.trim_prefix("maze_").trim_suffix(".tscn")
			var number = number_str.to_int()
			if number > max_number:
				max_number = number
		file_name = dir.get_next()
	
	return max_number + 1


func _set_owners_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_set_owners_recursive(child, owner)

