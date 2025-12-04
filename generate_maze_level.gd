# generate_maze_level.gd
# EditorScript to generate new maze scenes dynamically
# Run this script from: Tools > Run Script
# Each run creates a new maze scene in maze_levels/ folder

@tool
extends EditorScript

# Preload for headless mode compatibility
const MazeConfig = preload("res://maze_config.gd")
const MazeAlgorithm = preload("res://maze_algorithm.gd")
const MazeBuilder = preload("res://maze_builder.gd")

## Base path for maze levels
const MAZE_LEVELS_PATH = "res://maze_levels/"

## Maze scene template path (we'll create nodes programmatically)
var maze_scene_template = null


func _run() -> void:
	print("========================================")
	print("  Generate New Maze Level")
	print("========================================")
	
	# Ensure maze_levels directory exists
	if not DirAccess.dir_exists_absolute("res://maze_levels"):
		DirAccess.make_dir_recursive_absolute("res://maze_levels")
		print("[EditorScript] Created maze_levels directory")
	
	# Generate unique filename with timestamp
	var timestamp = Time.get_unix_time_from_system()
	var level_name = "maze_level_%d.tscn" % timestamp
	var level_path = MAZE_LEVELS_PATH + level_name
	
	print("[EditorScript] Generating new maze level: %s" % level_name)
	
	# Create config with defaults
	var config = MazeConfig.create_default()
	print("[EditorScript] Config: %d x %d" % [config.maze_width, config.maze_height])
	
	# Create the maze node
	var maze_node = Node3D.new()
	maze_node.name = "Maze"
	
	# Attach maze_generator script
	var generator_script = load("res://maze_generator.gd")
	if generator_script == null:
		push_error("[EditorScript] Failed to load maze_generator.gd!")
		return
	
	maze_node.set_script(generator_script)
	maze_node.config = config
	
	# Create scene tree
	var scene_root = Node3D.new()
	scene_root.name = "MazeLevel"
	scene_root.add_child(maze_node)
	maze_node.owner = scene_root
	
	# Generate the maze synchronously
	print("[EditorScript] Generating maze...")
	maze_node.generate_maze()
	
	# Wait for generation to complete
	for i in range(30):
		await Engine.get_main_loop().process_frame
	
	# Verify generation worked
	var floor_tiles = maze_node.get_node_or_null("FloorTiles")
	var walls = maze_node.get_node_or_null("Walls")
	
	if floor_tiles == null or walls == null:
		push_error("[EditorScript] Maze generation failed - nodes not found!")
		return
	
	var floor_count = floor_tiles.get_child_count()
	var wall_count = walls.get_child_count()
	
	print("[EditorScript] Generated:")
	print("  Floor tiles: %d" % floor_count)
	print("  Walls: %d" % wall_count)
	
	if floor_count == 0:
		push_error("[EditorScript] No floor tiles generated!")
		return
	
	# Set owners for all nodes (required for packing)
	_set_owners_recursive(scene_root, scene_root)
	
	# Pack the scene
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(scene_root)
	if result != OK:
		push_error("[EditorScript] Failed to pack scene! Error code: %d" % result)
		return
	
	# Save the scene
	print("[EditorScript] Saving scene to: %s" % level_path)
	var save_result = ResourceSaver.save(packed_scene, level_path)
	if save_result != OK:
		push_error("[EditorScript] Failed to save scene! Error code: %d" % save_result)
		return
	
	print("[EditorScript] Scene saved successfully!")
	print("[EditorScript] Maze level created: %s" % level_path)
	print("========================================")
	
	# Refresh file system
	EditorInterface.get_resource_filesystem().update_file(level_path)
	
	print("\n[EditorScript] Done! New maze level created in maze_levels/ folder.")


func _set_owners_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_set_owners_recursive(child, owner)

