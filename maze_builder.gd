# maze_builder.gd
# Constructs the 3D geometry for the maze using prefab scenes
# Uses floor_tile.tscn and wall_tile.tscn prefabs

class_name MazeBuilder
extends RefCounted

var _config: MazeConfig
var _parent_node: Node3D

# Prefab scenes
var _floor_prefab: PackedScene
var _wall_prefab: PackedScene

# Statistics for debugging
var _wall_count: int = 0
var _floor_count: int = 0


## Initializes the builder with configuration and parent node
func initialize(config: MazeConfig, parent: Node3D) -> void:
	_config = config
	_parent_node = parent
	_wall_count = 0
	_floor_count = 0
	
	print("[MazeBuilder] Initializing builder...")
	_load_prefabs()
	print("[MazeBuilder] Builder initialized")


## Loads the prefab scenes
func _load_prefabs() -> void:
	# Load floor prefab
	_floor_prefab = load("res://floor_tile.tscn")
	if _floor_prefab == null:
		push_error("[MazeBuilder] Failed to load floor_tile.tscn!")
		return
	
	# Load wall prefab
	_wall_prefab = load("res://wall_tile.tscn")
	if _wall_prefab == null:
		push_error("[MazeBuilder] Failed to load wall_tile.tscn!")
		return
	
	print("[MazeBuilder] Prefabs loaded successfully")


## Builds the complete maze from cell data
func build(cells: Array) -> void:
	print("[MazeBuilder] Starting maze construction...")
	
	var start_time = Time.get_ticks_msec()
	
	# Create floor tiles
	_create_floor_tiles(cells)
	
	# Create walls based on cell data
	_create_walls(cells)
	
	var elapsed = Time.get_ticks_msec() - start_time
	print("[MazeBuilder] Maze construction complete!")
	print("[MazeBuilder]   Floor tiles: %d" % _floor_count)
	print("[MazeBuilder]   Walls placed: %d" % _wall_count)
	print("[MazeBuilder]   Time elapsed: %d ms" % elapsed)


## Creates floor tiles for each cell
func _create_floor_tiles(cells: Array) -> void:
	var height = cells.size()
	if height == 0:
		push_error("[MazeBuilder] No cells provided!")
		return
	
	var width = cells[0].size()
	var tile_size = _config.tile_size
	
	print("[MazeBuilder] Creating floor tiles for %d x %d grid..." % [width, height])
	
	# Create a container node for floor tiles
	var floor_container = Node3D.new()
	floor_container.name = "FloorTiles"
	_parent_node.add_child(floor_container)
	
	# Create one floor tile per cell
	for y in range(height):
		for x in range(width):
			# Calculate tile center position
			var tile_center_x = (x + 0.5) * tile_size
			var tile_center_z = (y + 0.5) * tile_size
			var tile_pos = Vector3(tile_center_x, 0.05, tile_center_z)  # 0.05 to sit on ground
			
			# Instantiate floor prefab
			var floor_instance = _floor_prefab.instantiate()
			floor_instance.name = "Floor_%d_%d" % [x, y]
			floor_instance.position = tile_pos
			
			floor_container.add_child(floor_instance)
			_floor_count += 1
	
	print("[MazeBuilder] Created %d floor tiles" % _floor_count)


## Creates all walls based on cell data
func _create_walls(cells: Array) -> void:
	var height = cells.size()
	if height == 0:
		push_error("[MazeBuilder] No cells provided!")
		return
	
	var width = cells[0].size()
	var tile_size = _config.tile_size
	var wall_height = _config.wall_height
	
	print("[MazeBuilder] Creating walls for %d x %d grid..." % [width, height])
	
	# Create a container node for walls
	var walls_container = Node3D.new()
	walls_container.name = "Walls"
	_parent_node.add_child(walls_container)
	
	# Iterate through all cells
	for y in range(height):
		for x in range(width):
			var cell = cells[y][x]
			
			# Calculate cell center position in world space
			var cell_center_x = (x + 0.5) * tile_size
			var cell_center_z = (y + 0.5) * tile_size
			var wall_y = wall_height / 2.0  # Walls are centered vertically
			
			# North wall (at top edge of cell, blocks Z- direction)
			# This is an East-West oriented wall (runs along X axis)
			if cell["north"]:
				var wall_pos = Vector3(cell_center_x, wall_y, y * tile_size)
				_place_wall(walls_container, wall_pos, false, "Wall_N_%d_%d" % [x, y])
			
			# South wall (at bottom edge of cell, blocks Z+ direction)
			# Only place south walls for the last row to avoid duplicates
			# This is an East-West oriented wall
			if y == height - 1 and cell["south"]:
				var wall_pos = Vector3(cell_center_x, wall_y, (y + 1) * tile_size)
				_place_wall(walls_container, wall_pos, false, "Wall_S_%d_%d" % [x, y])
			
			# West wall (at left edge of cell, blocks X- direction)
			# This is a North-South oriented wall (runs along Z axis)
			if cell["west"]:
				var wall_pos = Vector3(x * tile_size, wall_y, cell_center_z)
				_place_wall(walls_container, wall_pos, true, "Wall_W_%d_%d" % [x, y])
			
			# East wall (at right edge of cell, blocks X+ direction)
			# Only place east walls for the last column to avoid duplicates
			# This is a North-South oriented wall
			if x == width - 1 and cell["east"]:
				var wall_pos = Vector3((x + 1) * tile_size, wall_y, cell_center_z)
				_place_wall(walls_container, wall_pos, true, "Wall_E_%d_%d" % [x, y])


## Places a single wall at the given position
## Parameters:
##   parent: Parent node to add wall to
##   position: World position for the wall
##   rotate_90: If true, rotate 90 degrees around Y axis (for N-S walls)
##   wall_name: Name for the wall instance
func _place_wall(parent: Node3D, position: Vector3, rotate_90: bool, wall_name: String) -> void:
	# Instantiate wall prefab
	var wall_instance = _wall_prefab.instantiate()
	wall_instance.name = wall_name
	wall_instance.position = position
	
	# Rotate if needed (for N-S walls, rotate 90 degrees around Y)
	if rotate_90:
		wall_instance.rotation_degrees.y = 90.0
	
	parent.add_child(wall_instance)
	_wall_count += 1


## Returns the number of walls created
func get_wall_count() -> int:
	return _wall_count


## Returns the number of floor tiles created
func get_floor_count() -> int:
	return _floor_count


## Clears all maze geometry from the parent node
func clear() -> void:
	print("[MazeBuilder] Clearing maze geometry...")
	
	# Find and remove floor container
	var floor_node = _parent_node.get_node_or_null("FloorTiles")
	if floor_node:
		floor_node.queue_free()
	
	# Find and remove walls container
	var walls_node = _parent_node.get_node_or_null("Walls")
	if walls_node:
		walls_node.queue_free()
	
	_wall_count = 0
	_floor_count = 0
	print("[MazeBuilder] Maze geometry cleared")
