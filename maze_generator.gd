# maze_generator.gd
# Main orchestrator script for procedural maze generation
# Attach this script to a Node3D in your scene
# @tool annotation allows this to run in the editor
#
# NOTE: This script CANNOT be run directly from Script Editor (File > Run)
#       because it extends Node3D, not EditorScript.
#       To manually generate the maze, use: generate_maze_editor.gd
#       Or simply open maze.tscn in the editor - it will generate automatically.

@tool
extends Node3D

## Configuration resource - can be set in editor or uses default
@export var config: MazeConfig

## Enable debug output
@export var debug_mode: bool = true

## Print ASCII representation of maze (useful for debugging small mazes)
@export var print_ascii_maze: bool = false

# Internal references
var _algorithm: MazeAlgorithm
var _builder: MazeBuilder
var _cells: Array


func _ready() -> void:
	print("========================================")
	print("  Procedural Maze Generator Started")
	print("========================================")
	
	# Initialize or create default config
	if config == null:
		print("[MazeGenerator] No config provided, using defaults")
		config = MazeConfig.create_default()
	
	# Check if config is a placeholder resource (common in editor)
	# Placeholder resources can't call methods, so check by accessing a property
	if Engine.is_editor_hint():
		# In editor, check if config is placeholder by trying to read a property
		var test_width = config.maze_width
		if test_width == 0 or config.resource_path == "":
			# Likely a placeholder, recreate config
			print("[MazeGenerator] Config appears to be placeholder, creating default config...")
			config = MazeConfig.create_default()
	
	# Validate configuration (skip if placeholder was detected)
	if config != null and config.resource_path != "":
		if not config.validate():
			push_error("[MazeGenerator] Invalid configuration! Aborting.")
			return
	
	# Print configuration if debug mode
	if debug_mode:
		config.print_config()
	
	# Generate the maze
	generate_maze()
	
	print("========================================")
	print("  Maze Generation Complete!")
	print("========================================")


## Main generation function - can be called to regenerate
func generate_maze() -> void:
	# Ensure config is initialized (in case generate_maze is called before _ready)
	if config == null:
		print("[MazeGenerator] Config not initialized, creating default config...")
		config = _create_default_config()
	else:
		# Check if config is a placeholder resource
		# Placeholder resources can't call methods, so we check by trying to read a property
		# If it fails or returns default values, it might be a placeholder
		var config_width = config.maze_width
		
		# If config has default/zero values, it might be uninitialized or placeholder
		# In editor context, if we can't safely validate, just recreate config
		if Engine.is_editor_hint():
			# In editor, if config seems like it might be placeholder, recreate it
			# We can't call validate() on placeholders, so check property access instead
			if config_width == 0:
				print("[MazeGenerator] Config appears uninitialized, creating default config...")
				config = _create_default_config()
			# Skip validation in editor to avoid placeholder issues
		else:
			# In runtime, validate normally
			if not config.validate():
				push_error("[MazeGenerator] Invalid configuration! Aborting.")
				return


## Helper function to create default config
func _create_default_config() -> MazeConfig:
	var new_config = MazeConfig.new()
	new_config.maze_width = 40
	new_config.maze_height = 40
	new_config.tile_size = 4.0
	new_config.wall_height = 3.0
	new_config.wall_thickness = 0.2
	new_config.floor_color = Color(0.6, 0.8, 0.5)
	new_config.wall_color = Color(0.65, 0.65, 0.65)
	new_config.entry_position = Vector2i(0, 0)
	new_config.exit_position = Vector2i(39, 39)
	return new_config
	
	var total_start = Time.get_ticks_msec()
	
	# Clear any existing maze
	_clear_existing_maze()
	
	# Step 1: Generate maze data using algorithm
	print("\n[MazeGenerator] Step 1: Generating maze layout...")
	_algorithm = MazeAlgorithm.new()
	_cells = _algorithm.generate(
		config.maze_width,
		config.maze_height,
		config.entry_position,
		config.exit_position,
		config.use_seed,
		config.random_seed
	)
	
	# Optional: Print ASCII representation
	if print_ascii_maze and config.maze_width <= 20 and config.maze_height <= 20:
		_algorithm.print_maze_ascii()
	elif print_ascii_maze:
		print("[MazeGenerator] ASCII maze printing skipped (maze too large, max 20x20)")
	
	# Step 2: Build 3D geometry
	print("\n[MazeGenerator] Step 2: Building 3D geometry...")
	_builder = MazeBuilder.new()
	_builder.initialize(config, self)
	_builder.build(_cells)
	
	var total_elapsed = Time.get_ticks_msec() - total_start
	print("\n[MazeGenerator] Total generation time: %d ms" % total_elapsed)


## Clears any existing maze geometry
func _clear_existing_maze() -> void:
	# In editor context, we need to remove children immediately
	# In runtime, queue_free works fine
	
	var floor_node = get_node_or_null("FloorTiles")
	if floor_node:
		if Engine.is_editor_hint():
			remove_child(floor_node)
			floor_node.queue_free()
		else:
			floor_node.queue_free()
	
	var walls_node = get_node_or_null("Walls")
	if walls_node:
		if Engine.is_editor_hint():
			remove_child(walls_node)
			walls_node.queue_free()
		else:
			walls_node.queue_free()
	
	# Also check for old format (backwards compatibility)
	var old_floor = get_node_or_null("Floor")
	if old_floor:
		if Engine.is_editor_hint():
			remove_child(old_floor)
			old_floor.queue_free()
		else:
			old_floor.queue_free()
	
	# In editor, we don't wait - nodes are freed immediately after removal
	# In runtime, we can wait if needed
	if not Engine.is_editor_hint() and is_inside_tree():
		await get_tree().process_frame


## Regenerates the maze with a new random seed
func regenerate_random() -> void:
	config.use_seed = false
	generate_maze()


## Regenerates the maze with a specific seed
func regenerate_with_seed(new_seed: int) -> void:
	config.use_seed = true
	config.random_seed = new_seed
	generate_maze()


## Returns the cell data at a given position (for external use)
func get_cell_data(x: int, y: int) -> Dictionary:
	if _cells.size() > y and _cells[y].size() > x:
		return _cells[y][x]
	return {}


## Returns the world position of a cell center
func get_cell_world_position(x: int, y: int) -> Vector3:
	var tile_size = config.tile_size
	return Vector3(
		(x + 0.5) * tile_size,
		0,
		(y + 0.5) * tile_size
	)


## Returns the entry point world position
func get_entry_world_position() -> Vector3:
	return get_cell_world_position(config.entry_position.x, config.entry_position.y)


## Returns the exit point world position
func get_exit_world_position() -> Vector3:
	return get_cell_world_position(config.exit_position.x, config.exit_position.y)


## Checks if a cell position is valid
func is_valid_cell(x: int, y: int) -> bool:
	return x >= 0 and x < config.maze_width and y >= 0 and y < config.maze_height


## Returns the maze dimensions
func get_maze_size() -> Vector2i:
	return Vector2i(config.maze_width, config.maze_height)


## Returns the total world size of the maze
func get_world_size() -> Vector2:
	return Vector2(config.get_total_width(), config.get_total_depth())
