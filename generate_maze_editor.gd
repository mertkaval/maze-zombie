# generate_maze_editor.gd
# EditorScript to manually generate the maze from Tools menu
# Run this script from: Tools > Run Script (or File > Run in Script Editor)
# 
# NOTE: To run maze_generator.gd, use THIS script instead.
# maze_generator.gd extends Node3D and is meant to be attached to a scene node.
# This EditorScript loads the maze scene, generates it, and saves it.

@tool
extends EditorScript

# Preload for headless mode compatibility
const MazeConfig = preload("res://maze_config.gd")

## Path to the maze scene
const MAZE_SCENE_PATH = "res://maze.tscn"


func _run() -> void:
	print("========================================")
	print("  EditorScript: Generating Maze")
	print("========================================")
	
	# Load the maze scene
	var maze_scene = load(MAZE_SCENE_PATH) as PackedScene
	if maze_scene == null:
		push_error("[EditorScript] Failed to load maze scene at: %s" % MAZE_SCENE_PATH)
		return
	
	print("[EditorScript] Loaded maze scene: %s" % MAZE_SCENE_PATH)
	
	# Instantiate the scene to get the root node
	var maze_instance = maze_scene.instantiate()
	if maze_instance == null:
		push_error("[EditorScript] Failed to instantiate maze scene!")
		return
	
	print("[EditorScript] Instantiated maze scene")
	
	# Find the Maze node (should be the root)
	var maze_node = maze_instance
	if maze_node.name != "Maze":
		# Try to find a child named Maze
		maze_node = maze_instance.get_node_or_null("Maze")
		if maze_node == null:
			push_error("[EditorScript] Could not find Maze node in scene!")
			maze_instance.queue_free()
			return
	
	# Check if the node has the maze_generator script
	if not maze_node.has_method("generate_maze"):
		push_error("[EditorScript] Maze node does not have generate_maze() method!")
		maze_instance.queue_free()
		return
	
	print("[EditorScript] Found Maze node with generate_maze() method")
	
	# Ensure config is initialized (fix placeholder issue)
	if maze_node.config == null:
		print("[EditorScript] Config is null, creating default config...")
		maze_node.config = MazeConfig.create_default()
	elif maze_node.config.resource_path == "" or maze_node.config.maze_width == 0:
		print("[EditorScript] Config appears to be placeholder, creating default config...")
		maze_node.config = MazeConfig.create_default()
	
	print("[EditorScript] Config initialized: %d x %d" % [maze_node.config.maze_width, maze_node.config.maze_height])
	print("[EditorScript] Calling generate_maze()...")
	
	# Call generate_maze() on the node
	# In editor mode, _clear_existing_maze() doesn't await, so this should complete synchronously
	maze_node.generate_maze()
	
	# Force process to ensure all nodes are created
	# In editor, we need to manually trigger updates
	EditorInterface.get_editor_viewport().queue_redraw()
	
	# Small delay to ensure nodes are created
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	
	print("[EditorScript] Maze generation complete!")
	
	# Verify generation worked
	var floor_tiles = maze_node.get_node_or_null("FloorTiles")
	var walls = maze_node.get_node_or_null("Walls")
	
	if floor_tiles == null:
		push_error("[EditorScript] FloorTiles container not found after generation!")
	else:
		print("[EditorScript] Floor tiles created: %d" % floor_tiles.get_child_count())
	
	if walls == null:
		push_error("[EditorScript] Walls container not found after generation!")
	else:
		print("[EditorScript] Walls created: %d" % walls.get_child_count())
	
	print("========================================")
	
	# Verify nodes were created before packing
	var floor_tiles_check = maze_node.get_node_or_null("FloorTiles")
	var walls_check = maze_node.get_node_or_null("Walls")
	
	if floor_tiles_check == null or walls_check == null:
		push_error("[EditorScript] Maze generation failed - nodes not found!")
		push_error("[EditorScript] FloorTiles: %s, Walls: %s" % [floor_tiles_check != null, walls_check != null])
		maze_instance.queue_free()
		return
	
	print("[EditorScript] Verifying maze structure...")
	print("[EditorScript]   Floor tiles: %d" % floor_tiles_check.get_child_count())
	print("[EditorScript]   Walls: %d" % walls_check.get_child_count())
	
	if floor_tiles_check.get_child_count() == 0:
		push_error("[EditorScript] No floor tiles created!")
		maze_instance.queue_free()
		return
	
	# Pack the scene with the generated maze
	print("[EditorScript] Packing scene...")
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(maze_instance)
	if result != OK:
		push_error("[EditorScript] Failed to pack scene! Error code: %d" % result)
		maze_instance.queue_free()
		return
	
	print("[EditorScript] Packing successful!")
	
	# Save the scene
	print("[EditorScript] Saving scene to: %s" % MAZE_SCENE_PATH)
	var save_result = ResourceSaver.save(packed_scene, MAZE_SCENE_PATH)
	if save_result != OK:
		push_error("[EditorScript] Failed to save scene! Error code: %d" % save_result)
		maze_instance.queue_free()
		return
	
	print("[EditorScript] Scene saved successfully!")
	print("[EditorScript] Open maze.tscn in the editor to see the generated maze.")
	
	# Clean up
	maze_instance.queue_free()
	
	# Reload the scene in the editor to show changes
	EditorInterface.reload_scene_from_path(MAZE_SCENE_PATH)
	
	print("\n[EditorScript] Done! The maze scene has been updated.")
	print("[EditorScript] If maze.tscn is open, it should now show the generated maze.")
