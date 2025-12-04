# maze_generator.gd
# Main orchestrator script for procedural maze generation
# Attach this script to a Node3D in your scene
# @tool annotation allows this to run in the editor
#
# NOTE: This script automatically generates the maze when attached to a scene node.
#       It's used by generate_maze_level.gd to create maze scenes dynamically.
#       The maze generates automatically via _ready() function.

@tool
extends Node3D

# Preload class_name scripts for headless mode compatibility
const MazeAlgorithm = preload("res://maze_algorithm.gd")
const MazeBuilder = preload("res://maze_builder.gd")
const MazeConfig = preload("res://maze_config.gd")

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
	
	# In editor, check if config is a placeholder and recreate only if needed
	# Placeholder resources can't call methods or reliably access properties
	if Engine.is_editor_hint():
		# Try to preserve seed values before checking if it's a placeholder
		# These might be set by regenerate_with_seed() or user modifications
		var saved_use_seed = false
		var saved_random_seed = 0
		var is_placeholder = false
		
		# Try to access seed values - if config is valid, preserve them
		# If accessing fails, we'll catch it and treat as placeholder
		var test_width = config.maze_width
		if test_width == 0:
			# Config appears uninitialized (placeholder or default)
			# Check if it's a placeholder by resource_path
			if config.resource_path == "":
				is_placeholder = true
		else:
			# Config seems valid, preserve seed values before any potential recreation
			saved_use_seed = config.use_seed
			saved_random_seed = config.random_seed
			# If resource_path is empty but width is valid, it's not a placeholder
			# (it might be a runtime-created config)
		
		# Only recreate if it's actually a placeholder (empty path AND zero width)
		if is_placeholder:
			print("[MazeGenerator] Editor mode detected - config is placeholder, recreating...")
			config = MazeConfig.create_default()
			# Restore preserved seed values
			config.use_seed = saved_use_seed
			config.random_seed = saved_random_seed
	
	# Validate configuration
	# In editor, skip validation entirely to avoid placeholder issues
	# Configs created with defaults are always valid
	# In runtime, validate normally (no placeholders at runtime)
	if not Engine.is_editor_hint():
		# Runtime: always validate
		if config != null:
			if not config.validate():
				push_error("[MazeGenerator] Invalid configuration! Aborting.")
				return
	# Editor: skip validation - configs are recreated if placeholders detected above
	
	# Print configuration if debug mode
	# Skip in editor if config might be a placeholder
	if debug_mode:
		if not Engine.is_editor_hint():
			# Runtime: safe to call print_config
			if config != null:
				config.print_config()
		else:
			# Editor: check if config is a placeholder before calling methods
			if config != null and config.resource_path != "":
				# Non-placeholder config, safe to call print_config
				config.print_config()
			else:
				# Placeholder config in editor - skip printing to avoid errors
				# Config will be recreated above if needed
				print("[MazeGenerator] Config printing skipped (placeholder in editor)")
	
	# Generate the maze
	generate_maze()
	
	print("========================================")
	print("  Maze Generation Complete!")
	print("========================================")


## Main generation function - can be called to regenerate
## Note: This function is async because it awaits maze cleanup
func generate_maze() -> void:
	# Ensure config is initialized (in case generate_maze is called before _ready)
	if config == null:
		print("[MazeGenerator] Config not initialized, creating default config...")
		config = _create_default_config()
	else:
		# Check if config is a placeholder or uninitialized
		if Engine.is_editor_hint():
			# In editor, check if config is a placeholder before recreating
			# Preserve seed values if config is valid (they might be set by regenerate_with_seed())
			var saved_use_seed = false
			var saved_random_seed = 0
			var is_placeholder = false
			
			# Try to access properties to determine if config is valid
			var test_width = config.maze_width
			if test_width == 0:
				# Config appears uninitialized - check if it's a placeholder
				if config.resource_path == "":
					is_placeholder = true
			else:
				# Config seems valid, preserve seed values before any potential recreation
				saved_use_seed = config.use_seed
				saved_random_seed = config.random_seed
			
			# Only recreate if it's actually a placeholder (empty path AND zero width)
			if is_placeholder:
				print("[MazeGenerator] Editor mode - config is placeholder, recreating...")
				config = _create_default_config()
				# Restore preserved seed values
				config.use_seed = saved_use_seed
				config.random_seed = saved_random_seed
		else:
			# In runtime, check if config is uninitialized (width == 0)
			var config_width = config.maze_width
			if config_width == 0:
				print("[MazeGenerator] Config appears uninitialized (width == 0), creating default config...")
				config = _create_default_config()
	
	# Validate configuration
	# In editor, we skip validation entirely to avoid placeholder issues
	# Configs created with _create_default_config() are always valid
	# In runtime, we always validate since placeholders don't exist at runtime
	if not Engine.is_editor_hint():
		# Runtime: always validate (no placeholders at runtime)
		if not config.validate():
			push_error("[MazeGenerator] Invalid configuration! Aborting.")
			return
	# Editor: skip validation to avoid placeholder issues
	# If config was recreated above, it's guaranteed to be valid
	# If config wasn't recreated, it means it passed our checks but might still be a placeholder
	# So we skip validation in editor entirely - configs created with defaults are always valid
	
	var total_start = Time.get_ticks_msec()
	
	# Clear any existing maze
	# In editor mode, this is synchronous (no await)
	# In runtime mode, this awaits for cleanup
	if Engine.is_editor_hint():
		_clear_existing_maze()
	else:
		await _clear_existing_maze()
	
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
	
	# In editor mode, force update to ensure nodes are visible
	if Engine.is_editor_hint():
		# Force the scene to update
		update_gizmos()


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


## Clears any existing maze geometry
## Note: This function is async in runtime mode to wait for node cleanup
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
## Note: This function is async because generate_maze() is async
func regenerate_random() -> void:
	config.use_seed = false
	await generate_maze()


## Regenerates the maze with a specific seed
## Note: This function is async because generate_maze() is async
func regenerate_with_seed(new_seed: int) -> void:
	config.use_seed = true
	config.random_seed = new_seed
	await generate_maze()


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
