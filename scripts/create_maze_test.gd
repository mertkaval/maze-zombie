# create_maze_test.gd
# Simple test script to create a maze scene
# Run with: godot --headless --path . --script scripts/create_maze_test.gd

extends SceneTree

const MazeConfig = preload("res://maze_config.gd")

const MAZE_LEVELS_PATH = "res://maze_levels/"


func _initialize() -> void:
	print("========================================")
	print("  Create Maze Test")
	print("========================================")
	
	# Ensure directory exists
	if not DirAccess.dir_exists_absolute("res://maze_levels"):
		DirAccess.make_dir_recursive_absolute("res://maze_levels")
		print("[Test] Created maze_levels directory")
	
	# Find next number
	var next_number = _find_next_maze_number()
	var level_name = "maze_%02d.tscn" % next_number
	var level_path = MAZE_LEVELS_PATH + level_name
	
	print("[Test] Creating: %s" % level_name)
	
	# Create config
	var config = MazeConfig.create_default()
	print("[Test] Config: %d x %d" % [config.maze_width, config.maze_height])
	
	# Create maze node
	var maze_node = Node3D.new()
	maze_node.name = "Maze"
	
	# Load and attach script
	var script = load("res://maze_generator.gd")
	if script == null:
		print("ERROR: Failed to load maze_generator.gd")
		quit(1)
		return
	
	maze_node.set_script(script)
	maze_node.config = config
	
	# Add to scene tree
	get_root().add_child(maze_node)
	maze_node.owner = get_root()
	
	# Wait for ready
	await process_frame
	await process_frame
	
	# Generate maze
	print("[Test] Generating maze...")
	maze_node.generate_maze()
	
	# Wait for completion
	for i in range(60):
		await process_frame
	
	# Check results
	var floor_tiles = maze_node.get_node_or_null("FloorTiles")
	var walls = maze_node.get_node_or_null("Walls")
	
	if floor_tiles == null:
		print("ERROR: FloorTiles not found")
		quit(1)
		return
	
	if walls == null:
		print("ERROR: Walls not found")
		quit(1)
		return
	
	var floor_count = floor_tiles.get_child_count()
	var wall_count = walls.get_child_count()
	
	print("[Test] Generated:")
	print("  Floor tiles: %d" % floor_count)
	print("  Walls: %d" % wall_count)
	
	if floor_count == 0:
		print("ERROR: No floor tiles!")
		quit(1)
		return
	
	# Remove from scene tree
	get_root().remove_child(maze_node)
	
	# Set owners
	_set_owners_recursive(maze_node, maze_node)
	
	# Pack scene
	var packed = PackedScene.new()
	var pack_result = packed.pack(maze_node)
	if pack_result != OK:
		print("ERROR: Failed to pack scene: %d" % pack_result)
		maze_node.queue_free()
		quit(1)
		return
	
	# Save scene
	print("[Test] Saving to: %s" % level_path)
	var save_result = ResourceSaver.save(packed, level_path)
	if save_result != OK:
		print("ERROR: Failed to save scene: %d" % save_result)
		maze_node.queue_free()
		quit(1)
		return
	
	print("[Test] SUCCESS! Scene saved: %s" % level_name)
	maze_node.queue_free()
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

