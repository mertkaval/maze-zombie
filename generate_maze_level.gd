# generate_maze_level.gd
# EditorScript to generate new maze scenes dynamically
# Run this script from: Tools > Run Script
# Each run creates a new maze scene in maze_levels/ folder
# Naming: maze_01.tscn, maze_02.tscn, maze_03.tscn, etc.

@tool
extends EditorScript

# MazeConfig is a class_name, no need to preload
const MAZE_LEVELS_PATH = "res://maze_levels/"


func _run() -> void:
	print("========================================")
	print("  Generate New Maze Level")
	print("========================================")
	
	# Ensure maze_levels directory exists
	if not DirAccess.dir_exists_absolute("res://maze_levels"):
		DirAccess.make_dir_recursive_absolute("res://maze_levels")
		print("[EditorScript] Created maze_levels directory")
	
	# Find next available maze number
	var next_number = _find_next_maze_number()
	var level_name = "maze_%02d.tscn" % next_number
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
	
	# Create a temporary scene tree to add the node to
	# This allows _ready() and generation to work properly
	var temp_root = Node3D.new()
	temp_root.name = "TempRoot"
	
	# Get or create editor scene root
	var editor_root = EditorInterface.get_edited_scene_root()
	if editor_root == null:
		# No scene open - use the current scene tree
		# EditorScript runs in editor context, so we can use the base control's tree
		var base_tree = EditorInterface.get_base_control().get_tree()
		if base_tree != null and base_tree.get_root() != null:
			base_tree.get_root().add_child(temp_root)
			temp_root.add_child(maze_node)
			maze_node.owner = temp_root
		else:
			push_error("[EditorScript] Cannot access editor scene tree!")
			return
	else:
		# Scene is open - add to it
		editor_root.add_child(temp_root)
		temp_root.add_child(maze_node)
		maze_node.owner = editor_root
	
	# Wait for _ready() to be called and complete
	# _ready() will automatically call generate_maze()
	print("[EditorScript] Waiting for maze node initialization...")
	for i in range(10):
		await Engine.get_main_loop().process_frame
	
	# Wait for generation to complete (maze_generator._ready() calls generate_maze())
	# For a 40x40 maze, this can take a while
	print("[EditorScript] Waiting for maze generation...")
	var generation_complete = false
	var wait_count = 0
	var max_wait = 200  # Increased wait time for large mazes
	
	while not generation_complete and wait_count < max_wait:
		await Engine.get_main_loop().process_frame
		wait_count += 1
		
		# Check if generation is complete by looking for FloorTiles and Walls
		var floor_tiles = maze_node.get_node_or_null("FloorTiles")
		var walls = maze_node.get_node_or_null("Walls")
		
		if floor_tiles != null and walls != null:
			var floor_count = floor_tiles.get_child_count()
			var wall_count = walls.get_child_count()
			
			# Generation is complete when we have expected floor tiles
			var expected_floors = config.maze_width * config.maze_height
			if floor_count >= expected_floors and floor_count > 0:
				generation_complete = true
				print("[EditorScript] Generation complete!")
				print("[EditorScript]   Floor tiles: %d" % floor_count)
				print("[EditorScript]   Walls: %d" % wall_count)
				break
	
	if not generation_complete:
		push_error("[EditorScript] Maze generation timed out or failed!")
		var floor_tiles = maze_node.get_node_or_null("FloorTiles")
		var walls = maze_node.get_node_or_null("Walls")
		if floor_tiles == null or walls == null:
			push_error("[EditorScript] FloorTiles or Walls nodes not found!")
			temp_root.queue_free()
			return
		else:
			var floor_count = floor_tiles.get_child_count()
			var wall_count = walls.get_child_count()
			print("[EditorScript] Partial generation: %d floors, %d walls" % [floor_count, wall_count])
			if floor_count == 0:
				temp_root.queue_free()
				return
	
	# Remove from temporary scene tree
	temp_root.remove_child(maze_node)
	temp_root.queue_free()
	
	# Set owners for all nodes (required for packing)
	# The Maze node will be the root of the saved scene
	_set_owners_recursive(maze_node, maze_node)
	
	# Pack the scene
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(maze_node)
	if result != OK:
		push_error("[EditorScript] Failed to pack scene! Error code: %d" % result)
		maze_node.queue_free()
		return
	
	# Save the scene
	print("[EditorScript] Saving scene to: %s" % level_path)
	var save_result = ResourceSaver.save(packed_scene, level_path)
	if save_result != OK:
		push_error("[EditorScript] Failed to save scene! Error code: %d" % save_result)
		maze_node.queue_free()
		return
	
	print("[EditorScript] Scene saved successfully!")
	print("[EditorScript] Maze level created: %s" % level_path)
	print("========================================")
	
	# Refresh file system
	EditorInterface.get_resource_filesystem().update_file(level_path)
	
	# Clean up
	maze_node.queue_free()
	
	print("\n[EditorScript] Done! New maze level created: %s" % level_name)


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
