# generate_maze_editor.gd
# EditorScript to manually generate the maze from Tools menu
# Run this script from: Tools > Run Script (or File > Run in Script Editor)
# 
# NOTE: To run maze_generator.gd, use THIS script instead.
# maze_generator.gd extends Node3D and is meant to be attached to a scene node.
# This EditorScript loads the maze scene, generates it, and saves it.

@tool
extends EditorScript

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
	print("[EditorScript] Calling generate_maze()...")
	
	# Call generate_maze() on the node
	maze_node.generate_maze()
	
	print("[EditorScript] Maze generation complete!")
	print("========================================")
	
	# Pack the scene with the generated maze
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(maze_instance)
	if result != OK:
		push_error("[EditorScript] Failed to pack scene! Error code: %d" % result)
		maze_instance.queue_free()
		return
	
	# Save the scene
	var save_result = ResourceSaver.save(packed_scene, MAZE_SCENE_PATH)
	if save_result != OK:
		push_error("[EditorScript] Failed to save scene! Error code: %d" % save_result)
	else:
		print("[EditorScript] Scene saved successfully!")
		print("[EditorScript] Open maze.tscn in the editor to see the generated maze.")
	
	# Clean up
	maze_instance.queue_free()
	
	print("\n[EditorScript] Done! Open maze.tscn in the editor to view the maze.")
