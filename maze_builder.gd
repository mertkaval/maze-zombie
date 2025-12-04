# maze_builder.gd
# Constructs the 3D geometry for the maze using direct node creation
# Avoids PackedScene.instantiate() to prevent editor dialog errors

class_name MazeBuilder
extends RefCounted

# Preload for headless mode compatibility
const MazeConfig = preload("res://maze_config.gd")

# Cached materials (created once, reused for all tiles)
var _floor_material: StandardMaterial3D
var _wall_material: StandardMaterial3D

# Configuration
var _config: MazeConfig
var _parent_node: Node3D

# Calculated dimensions (from config, no hardcoding)
var _tile_size: float
var _wall_height: float
var _wall_thickness: float
var _floor_height: float = 0.1

# Statistics for debugging
var _wall_count: int = 0
var _floor_count: int = 0


## Initializes the builder with configuration and parent node
func initialize(config: MazeConfig, parent: Node3D) -> void:
	_config = config
	_parent_node = parent
	_wall_count = 0
	_floor_count = 0
	
	# Cache config values for calculations
	_tile_size = config.tile_size
	_wall_height = config.wall_height
	_wall_thickness = config.wall_thickness
	
	print("[MazeBuilder] Initializing builder...")
	_create_materials()
	print("[MazeBuilder] Builder initialized (direct geometry mode)")
	print("[MazeBuilder]   Tile size: %.2f" % _tile_size)
	print("[MazeBuilder]   Wall height: %.2f" % _wall_height)
	print("[MazeBuilder]   Wall thickness: %.2f" % _wall_thickness)


## Creates cached materials for floor and wall tiles
func _create_materials() -> void:
	# Create floor material
	_floor_material = StandardMaterial3D.new()
	_floor_material.albedo_color = _config.floor_color
	
	# Create wall material
	_wall_material = StandardMaterial3D.new()
	_wall_material.albedo_color = _config.wall_color


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
	
	print("[MazeBuilder] Creating floor tiles for %d x %d grid..." % [width, height])
	
	# Create a container node for floor tiles
	var floor_container = Node3D.new()
	floor_container.name = "FloorTiles"
	_parent_node.add_child(floor_container)
	
	# Create one floor tile per cell
	for y in range(height):
		for x in range(width):
			var tile = _create_floor_tile(x, y)
			floor_container.add_child(tile)
			_floor_count += 1
	
	print("[MazeBuilder] Created %d floor tiles" % _floor_count)


## Creates a floor tile at the specified cell position
func _create_floor_tile(x: int, y: int) -> StaticBody3D:
	var tile = StaticBody3D.new()
	tile.name = "Floor_%d_%d" % [x, y]
	
	# Position at cell center, slightly above origin
	tile.position = Vector3(
		(x + 0.5) * _tile_size,
		_floor_height / 2.0,
		(y + 0.5) * _tile_size
	)
	
	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var mesh = BoxMesh.new()
	mesh.size = Vector3(_tile_size, _floor_height, _tile_size)
	mesh.material = _floor_material
	mesh_instance.mesh = mesh
	tile.add_child(mesh_instance)
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape = BoxShape3D.new()
	shape.size = Vector3(_tile_size, _floor_height, _tile_size)
	collision.shape = shape
	tile.add_child(collision)
	
	return tile


## Creates all walls based on cell data
func _create_walls(cells: Array) -> void:
	var height = cells.size()
	if height == 0:
		push_error("[MazeBuilder] No cells provided!")
		return
	
	var width = cells[0].size()
	
	print("[MazeBuilder] Creating walls for %d x %d grid..." % [width, height])
	
	# Create a container node for walls
	var walls_container = Node3D.new()
	walls_container.name = "Walls"
	_parent_node.add_child(walls_container)
	
	# Iterate through all cells
	for y in range(height):
		for x in range(width):
			var cell = cells[y][x]
			
			# North wall (every cell that has north=true)
			# Placed at Z = y * tile_size (top edge of cell)
			# Rotated 90° so wall runs along X axis
			if cell["north"]:
				var pos = _get_ns_wall_position(x, y * _tile_size)
				var wall = _create_wall_tile(pos, 90.0, "Wall_N_%d_%d" % [x, y])
				walls_container.add_child(wall)
				_wall_count += 1
			
			# South wall (only bottom row to avoid duplicates)
			# Placed at Z = (y + 1) * tile_size (bottom edge of last row)
			# Rotated 90° so wall runs along X axis
			if y == height - 1 and cell["south"]:
				var pos = _get_ns_wall_position(x, (y + 1) * _tile_size)
				var wall = _create_wall_tile(pos, 90.0, "Wall_S_%d_%d" % [x, y])
				walls_container.add_child(wall)
				_wall_count += 1
			
			# West wall (every cell that has west=true)
			# Placed at X = x * tile_size (left edge of cell)
			# No rotation - wall runs along Z axis
			if cell["west"]:
				var pos = _get_ew_wall_position(x * _tile_size, y)
				var wall = _create_wall_tile(pos, 0.0, "Wall_W_%d_%d" % [x, y])
				walls_container.add_child(wall)
				_wall_count += 1
			
			# East wall (only right column to avoid duplicates)
			# Placed at X = (x + 1) * tile_size (right edge of last column)
			# No rotation - wall runs along Z axis
			if x == width - 1 and cell["east"]:
				var pos = _get_ew_wall_position((x + 1) * _tile_size, y)
				var wall = _create_wall_tile(pos, 0.0, "Wall_E_%d_%d" % [x, y])
				walls_container.add_child(wall)
				_wall_count += 1


## Calculates position for North/South walls (run along X axis, block Z movement)
func _get_ns_wall_position(cell_x: int, edge_z: float) -> Vector3:
	return Vector3(
		(cell_x + 0.5) * _tile_size,          # Center of cell X
		_floor_height + _wall_height / 2.0,   # Sit on floor (floor top + half wall height)
		edge_z                                 # At the edge (north or south)
	)


## Calculates position for East/West walls (run along Z axis, block X movement)
func _get_ew_wall_position(edge_x: float, cell_y: int) -> Vector3:
	return Vector3(
		edge_x,                               # At the edge (east or west)
		_floor_height + _wall_height / 2.0,   # Sit on floor (floor top + half wall height)
		(cell_y + 0.5) * _tile_size           # Center of cell Z
	)


## Creates a wall tile at the specified position with rotation
func _create_wall_tile(pos: Vector3, rotation_y: float, wall_name: String) -> StaticBody3D:
	var wall = StaticBody3D.new()
	wall.name = wall_name
	wall.position = pos
	wall.rotation_degrees.y = rotation_y
	
	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var mesh = BoxMesh.new()
	# Size: thickness x height x length (tile_size)
	mesh.size = Vector3(_wall_thickness, _wall_height, _tile_size)
	mesh.material = _wall_material
	mesh_instance.mesh = mesh
	wall.add_child(mesh_instance)
	
	# Create collision shape
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape = BoxShape3D.new()
	shape.size = Vector3(_wall_thickness, _wall_height, _tile_size)
	collision.shape = shape
	wall.add_child(collision)
	
	return wall


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
