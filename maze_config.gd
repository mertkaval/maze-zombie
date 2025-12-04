# maze_config.gd
# Configuration resource for the procedural maze generator
# All maze parameters are defined here for easy tweaking

class_name MazeConfig
extends Resource

## Maze Dimensions
@export_group("Maze Dimensions")
@export var maze_width: int = 20  ## Number of tiles in X direction
@export var maze_height: int = 20  ## Number of tiles in Z direction

## Tile Properties
@export_group("Tile Properties")
@export var tile_size: float = 4.0  ## Size of each floor tile in meters
@export var wall_height: float = 6.0  ## Height of walls in meters
@export var wall_thickness: float = 0.2  ## Thickness of walls in meters

## Colors
@export_group("Colors")
@export var floor_color: Color = Color(0.6, 0.8, 0.5)  ## Soft green
@export var wall_color: Color = Color(0.65, 0.65, 0.65)  ## Soft grey

## Generation Settings
@export_group("Generation")
@export var use_seed: bool = false  ## Whether to use a fixed seed
@export var random_seed: int = 0  ## Seed for reproducible mazes

## Entry/Exit Settings
@export_group("Entry and Exit")
@export var entry_position: Vector2i = Vector2i(0, 0)  ## Entry cell position
@export var exit_position: Vector2i = Vector2i(39, 39)  ## Exit cell position


## Returns the total maze width in world units (meters)
func get_total_width() -> float:
	return maze_width * tile_size


## Returns the total maze height/depth in world units (meters)
func get_total_depth() -> float:
	return maze_height * tile_size


## Validates the configuration and returns true if valid
func validate() -> bool:
	if maze_width < 2 or maze_height < 2:
		push_error("MazeConfig: Maze dimensions must be at least 2x2")
		return false
	if tile_size <= 0:
		push_error("MazeConfig: Tile size must be positive")
		return false
	if wall_height <= 0:
		push_error("MazeConfig: Wall height must be positive")
		return false
	if wall_thickness <= 0 or wall_thickness >= tile_size:
		push_error("MazeConfig: Wall thickness must be positive and less than tile size")
		return false
	if entry_position.x < 0 or entry_position.x >= maze_width or entry_position.y < 0 or entry_position.y >= maze_height:
		push_error("MazeConfig: Entry position is outside maze bounds")
		return false
	if exit_position.x < 0 or exit_position.x >= maze_width or exit_position.y < 0 or exit_position.y >= maze_height:
		push_error("MazeConfig: Exit position is outside maze bounds")
		return false
	return true


## Creates a default configuration
static func create_default() -> MazeConfig:
	var config = MazeConfig.new()
	# All defaults are already set via @export
	return config


## Prints configuration for debugging
func print_config() -> void:
	print("=== Maze Configuration ===")
	print("  Dimensions: %d x %d tiles" % [maze_width, maze_height])
	print("  Tile size: %.1f m" % tile_size)
	print("  Wall height: %.1f m" % wall_height)
	print("  Wall thickness: %.1f m" % wall_thickness)
	print("  Total area: %.1f x %.1f m" % [get_total_width(), get_total_depth()])
	print("  Floor color: %s" % floor_color)
	print("  Wall color: %s" % wall_color)
	print("  Entry: (%d, %d)" % [entry_position.x, entry_position.y])
	print("  Exit: (%d, %d)" % [exit_position.x, exit_position.y])
	if use_seed:
		print("  Seed: %d" % random_seed)
	else:
		print("  Seed: Random")
	print("==========================")
