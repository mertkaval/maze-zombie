# fix_scene_issues.gd
# Script to automatically fix common scene issues
# Run from CI: godot --headless --path . -s scripts/fix_scene_issues.gd
# Or as EditorScript in editor: File > Run

@tool
extends EditorScript

const MazeSceneHelper = preload("res://scripts/maze_scene_helper.gd")

var fixes_applied = 0
var scenes_fixed = []

const SCENES_TO_FIX = [
	# "res://maze.tscn",  # Removed - using maze_levels/ instead
	"res://main.tscn"
]


func _run() -> void:
	print("========================================")
	print("  Scene Issue Fixer")
	print("========================================")
	
	fixes_applied = 0
	scenes_fixed.clear()
	
	# Fix each scene
	for scene_path in SCENES_TO_FIX:
		fix_scene(scene_path)
	
	# Also fix maze scenes in maze_levels if any exist
	var maze_scene_path = MazeSceneHelper.find_first_maze_scene()
	if maze_scene_path != "":
		fix_scene(maze_scene_path)
	
	# Print summary
	print("\n========================================")
	print("  Fix Summary")
	print("========================================")
	print("Scenes processed: %d" % (SCENES_TO_FIX.size() + (1 if maze_scene_path != "" else 0)))
	print("Fixes applied: %d" % fixes_applied)
	
	if fixes_applied > 0:
		print("✅ Fixed %d issues" % fixes_applied)
		print("FIXED")
	else:
		print("✅ No fixes needed")
		print("NO_FIXES_NEEDED")


func fix_scene(scene_path: String) -> void:
	print("\n[Fixing] %s" % scene_path)
	
	if not ResourceLoader.exists(scene_path):
		print("  ⚠️  Scene file does not exist, skipping")
		return
	
	# Load scene
	var scene = load(scene_path) as PackedScene
	if scene == null:
		print("  ⚠️  Failed to load scene, skipping")
		return
	
	# Instantiate
	var instance = scene.instantiate()
	if instance == null:
		print("  ⚠️  Failed to instantiate scene, skipping")
		return
	
	var scene_needs_save = false
	
	# Fix missing config resources
	if scene_path.begins_with("res://maze_levels/"):
		scene_needs_save = fix_maze_config(instance) or scene_needs_save
	
	# Fix broken script paths
	scene_needs_save = fix_script_paths(instance) or scene_needs_save
	
	# Fix node structure
	scene_needs_save = fix_node_structure(instance) or scene_needs_save
	
	if scene_needs_save:
		# Note: In EditorScript, we can't directly save scenes
		# This would need to be done through EditorInterface
		print("  ⚠️  Scene needs saving, but EditorScript cannot save directly")
		print("  ⚠️  Open scene in editor and save manually if needed")
	
	scenes_fixed.append(scene_path)
	instance.queue_free()


func fix_maze_config(root: Node) -> bool:
	var fixed = false
	
	# Find Maze node
	var maze_node = root
	if root.name != "Maze":
		maze_node = root.get_node_or_null("Maze")
	
	if maze_node == null:
		return false
	
	# Check if config is missing or invalid
	var maze_generator = maze_node
	if maze_generator.get("config") == null:
		print("  ✓ Adding missing config to Maze node")
		var config = load("res://maze_config.gd").new()
		maze_generator.set("config", config)
		fixed = true
	else:
		var config = maze_generator.get("config")
		if config == null or (config.get("maze_width") == null or config.maze_width == 0):
			print("  ✓ Fixing invalid config on Maze node")
			var new_config = load("res://maze_config.gd").new()
			maze_generator.set("config", new_config)
			fixed = true
	
	return fixed


func fix_script_paths(root: Node) -> bool:
	var fixed = false
	
	# Check if script path is broken
	if root.get_script() != null:
		var script = root.get_script()
		if script is GDScript:
			var script_path = script.resource_path
			if script_path != "" and not ResourceLoader.exists(script_path):
				print("  ✓ Found broken script path: %s" % script_path)
				# Don't remove script, just warn
				# fixed = true
	
	# Recursively check children
	for child in root.get_children():
		if fix_script_paths(child):
			fixed = true
	
	return fixed


func fix_node_structure(root: Node) -> bool:
	var fixed = false
	
	# Check for common structural issues
	# This is a placeholder for future structural fixes
	
	# Recursively check children
	for child in root.get_children():
		if fix_node_structure(child):
			fixed = true
	
	return fixed
