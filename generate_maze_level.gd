# generate_maze_level.gd
# EditorScript to generate new maze scenes dynamically
# Run this script from: Tools > Run Script
# Each run creates a new maze scene in maze_levels/ folder
# Naming: maze_01.tscn, maze_02.tscn, maze_03.tscn, etc.

@tool
extends EditorScript

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
	
	# Create root Maze node (plain Node3D, NO script attached)
	# This avoids @tool script complications
	var maze_node = Node3D.new()
	maze_node.name = "Maze"
	
	# Generate maze data directly using MazeAlgorithm
	print("[EditorScript] Step 1: Generating maze layout...")
	var algorithm = MazeAlgorithm.new()
	var cells = algorithm.generate(
		config.maze_width,
		config.maze_height,
		config.entry_position,
		config.exit_position,
		config.use_seed,
		config.random_seed
	)
	
	# Build 3D geometry directly using MazeBuilder
	print("[EditorScript] Step 2: Building 3D geometry...")
	var builder = MazeBuilder.new()
	builder.initialize(config, maze_node)
	builder.build(cells)
	
	# === VERIFICATION ===
	var floor_container = maze_node.get_node_or_null("FloorTiles")
	var walls_container = maze_node.get_node_or_null("Walls")
	
	if floor_container == null:
		push_error("[EditorScript] FloorTiles container not created!")
		maze_node.free()
		return
	
	if walls_container == null:
		push_error("[EditorScript] Walls container not created!")
		maze_node.free()
		return
	
	var expected_floors = config.maze_width * config.maze_height
	var actual_floors = floor_container.get_child_count()
	var actual_walls = walls_container.get_child_count()
	
	if actual_floors != expected_floors:
		push_error("[EditorScript] Expected %d floors, got %d" % [expected_floors, actual_floors])
		maze_node.free()
		return
	
	if actual_walls == 0:
		push_error("[EditorScript] No walls generated!")
		maze_node.free()
		return
	
	print("[EditorScript] Verification passed!")
	print("[EditorScript]   Floor tiles: %d" % actual_floors)
	print("[EditorScript]   Walls: %d" % actual_walls)
	
	# Set owners for all nodes (required for packing)
	print("[EditorScript] Setting node owners for packing...")
	_set_owners_recursive(maze_node, maze_node)
	
	# Pack the scene
	print("[EditorScript] Packing scene...")
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(maze_node)
	if result != OK:
		push_error("[EditorScript] Failed to pack scene! Error code: %d" % result)
		maze_node.free()
		return
	
	# Save the scene
	print("[EditorScript] Saving scene to: %s" % level_path)
	var save_result = ResourceSaver.save(packed_scene, level_path)
	if save_result != OK:
		push_error("[EditorScript] Failed to save scene! Error code: %d" % save_result)
		maze_node.free()
		return
	
	print("[EditorScript] Scene saved successfully!")
	print("[EditorScript] Maze level created: %s" % level_path)
	print("========================================")
	
	# Clean up - use free() not queue_free() since not in tree
	maze_node.free()
	
	print("\n[EditorScript] Done! New maze level created: %s" % level_name)
	print("[EditorScript] You can now open %s in the editor." % level_path)
	print("[EditorScript] If the file doesn't appear, right-click the maze_levels folder and select 'Refresh'.")


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


func _set_owners_recursive(node: Node, owner_node: Node) -> void:
	# Set owner for all children (not the root itself)
	for child in node.get_children():
		child.owner = owner_node
		_set_owners_recursive(child, owner_node)
