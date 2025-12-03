# maze_algorithm.gd
# Implements the Recursive Backtracking (Depth-First Search) maze generation algorithm
# Returns a 2D array of cells with wall information

class_name MazeAlgorithm
extends RefCounted

## Cell data structure - stores wall state for each direction
## Each cell is a Dictionary with keys: north, south, east, west (bool - true means wall exists)


## Direction vectors for maze traversal
const DIRECTIONS = {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0)
}

## Opposite direction mapping for wall removal
const OPPOSITE = {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east"
}

var _width: int
var _height: int
var _cells: Array  # 2D array of cell dictionaries
var _visited: Array  # 2D array of booleans


## Generates a maze and returns the cell data
## Parameters:
##   width: Number of cells in X direction
##   height: Number of cells in Z direction
##   entry: Entry cell position
##   exit: Exit cell position
##   use_seed: Whether to use a fixed seed
##   seed_value: The seed value if use_seed is true
func generate(width: int, height: int, entry: Vector2i, exit: Vector2i, use_seed: bool = false, seed_value: int = 0) -> Array:
	print("[MazeAlgorithm] Starting maze generation...")
	print("[MazeAlgorithm] Size: %d x %d" % [width, height])
	
	_width = width
	_height = height
	
	# Initialize random seed
	if use_seed:
		seed(seed_value)
		print("[MazeAlgorithm] Using seed: %d" % seed_value)
	else:
		randomize()
		print("[MazeAlgorithm] Using random seed")
	
	# Initialize cells with all walls
	_initialize_cells()
	
	# Initialize visited array
	_initialize_visited()
	
	# Generate maze using recursive backtracking
	_recursive_backtrack(entry)
	
	# Open entry and exit on outer walls
	_open_entry_exit(entry, exit)
	
	print("[MazeAlgorithm] Maze generation complete!")
	
	return _cells


## Initializes all cells with all walls present
func _initialize_cells() -> void:
	_cells = []
	for y in range(_height):
		var row = []
		for x in range(_width):
			row.append(_create_cell())
		_cells.append(row)
	print("[MazeAlgorithm] Initialized %d cells" % (_width * _height))


## Creates a new cell with all walls
func _create_cell() -> Dictionary:
	return {
		"north": true,
		"south": true,
		"east": true,
		"west": true
	}


## Initializes the visited tracking array
func _initialize_visited() -> void:
	_visited = []
	for y in range(_height):
		var row = []
		for x in range(_width):
			row.append(false)
		_visited.append(row)


## Recursive backtracking algorithm (iterative implementation to avoid stack overflow)
func _recursive_backtrack(start: Vector2i) -> void:
	var stack: Array[Vector2i] = []
	stack.append(start)
	_visited[start.y][start.x] = true
	var cells_visited = 1
	var total_cells = _width * _height
	
	while stack.size() > 0:
		var current = stack[stack.size() - 1]
		var neighbors = _get_unvisited_neighbors(current)
		
		if neighbors.size() > 0:
			# Choose random neighbor
			var random_index = randi() % neighbors.size()
			var next_data = neighbors[random_index]
			var next_pos: Vector2i = next_data["pos"]
			var direction: String = next_data["dir"]
			
			# Remove wall between current and next
			_remove_wall(current, next_pos, direction)
			
			# Mark as visited and add to stack
			_visited[next_pos.y][next_pos.x] = true
			stack.append(next_pos)
			cells_visited += 1
			
			# Progress logging every 10%
			# Avoid division by zero for small mazes (minimum is 2x2=4 cells)
			if total_cells >= 10 and cells_visited % (total_cells / 10) == 0:
				var progress = (cells_visited * 100) / total_cells
				print("[MazeAlgorithm] Progress: %d%%" % progress)
		else:
			# Backtrack
			stack.pop_back()


## Gets all unvisited neighboring cells
func _get_unvisited_neighbors(pos: Vector2i) -> Array:
	var neighbors = []
	
	for dir_name in DIRECTIONS.keys():
		var dir_vec = DIRECTIONS[dir_name]
		var neighbor_pos = pos + dir_vec
		
		if _is_valid_cell(neighbor_pos) and not _visited[neighbor_pos.y][neighbor_pos.x]:
			neighbors.append({
				"pos": neighbor_pos,
				"dir": dir_name
			})
	
	return neighbors


## Checks if a cell position is within bounds
func _is_valid_cell(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < _width and pos.y >= 0 and pos.y < _height


## Removes the wall between two adjacent cells
func _remove_wall(current: Vector2i, next: Vector2i, direction: String) -> void:
	# Remove wall from current cell
	_cells[current.y][current.x][direction] = false
	
	# Remove opposite wall from next cell
	var opposite_dir = OPPOSITE[direction]
	_cells[next.y][next.x][opposite_dir] = false


## Opens entry and exit points on the outer walls
## Also ensures all outer edges are closed except at entry/exit
func _open_entry_exit(entry: Vector2i, exit: Vector2i) -> void:
	# First, ensure all outer edges are closed
	# Close north edge (top row)
	for x in range(_width):
		_cells[0][x]["north"] = true
	
	# Close south edge (bottom row)
	for x in range(_width):
		_cells[_height - 1][x]["south"] = true
	
	# Close west edge (left column)
	for y in range(_height):
		_cells[y][0]["west"] = true
	
	# Close east edge (right column)
	for y in range(_height):
		_cells[y][_width - 1]["east"] = true
	
	# Now open entry - remove appropriate outer wall
	if entry.x == 0:
		_cells[entry.y][entry.x]["west"] = false
		print("[MazeAlgorithm] Entry opened on west wall at (%d, %d)" % [entry.x, entry.y])
	elif entry.x == _width - 1:
		_cells[entry.y][entry.x]["east"] = false
		print("[MazeAlgorithm] Entry opened on east wall at (%d, %d)" % [entry.x, entry.y])
	elif entry.y == 0:
		_cells[entry.y][entry.x]["north"] = false
		print("[MazeAlgorithm] Entry opened on north wall at (%d, %d)" % [entry.x, entry.y])
	elif entry.y == _height - 1:
		_cells[entry.y][entry.x]["south"] = false
		print("[MazeAlgorithm] Entry opened on south wall at (%d, %d)" % [entry.x, entry.y])
	
	# Open exit - remove appropriate outer wall
	if exit.x == _width - 1:
		_cells[exit.y][exit.x]["east"] = false
		print("[MazeAlgorithm] Exit opened on east wall at (%d, %d)" % [exit.x, exit.y])
	elif exit.x == 0:
		_cells[exit.y][exit.x]["west"] = false
		print("[MazeAlgorithm] Exit opened on west wall at (%d, %d)" % [exit.x, exit.y])
	elif exit.y == _height - 1:
		_cells[exit.y][exit.x]["south"] = false
		print("[MazeAlgorithm] Exit opened on south wall at (%d, %d)" % [exit.x, exit.y])
	elif exit.y == 0:
		_cells[exit.y][exit.x]["north"] = false
		print("[MazeAlgorithm] Exit opened on north wall at (%d, %d)" % [exit.x, exit.y])


## Returns the cell data at a given position
func get_cell(x: int, y: int) -> Dictionary:
	if x >= 0 and x < _width and y >= 0 and y < _height:
		return _cells[y][x]
	return {}


## Prints maze to console for debugging (ASCII representation)
func print_maze_ascii() -> void:
	print("\n[MazeAlgorithm] ASCII Maze Representation:")
	
	# Top border
	var top_line = "+"
	for x in range(_width):
		if _cells[0][x]["north"]:
			top_line += "---+"
		else:
			top_line += "   +"
	print(top_line)
	
	# Each row
	for y in range(_height):
		var mid_line = ""
		var bottom_line = "+"
		
		for x in range(_width):
			var cell = _cells[y][x]
			
			# West wall and cell content
			if cell["west"]:
				mid_line += "|"
			else:
				mid_line += " "
			mid_line += "   "
			
			# East wall (only for last column)
			if x == _width - 1:
				if cell["east"]:
					mid_line += "|"
				else:
					mid_line += " "
			
			# South wall
			if cell["south"]:
				bottom_line += "---+"
			else:
				bottom_line += "   +"
		
		print(mid_line)
		print(bottom_line)
