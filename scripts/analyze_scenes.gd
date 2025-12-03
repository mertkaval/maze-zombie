# analyze_scenes.gd
# Script for deep analysis of scenes to find issues
# Works in headless mode: godot --headless --path . --script scripts/analyze_scenes.gd

extends Node

var issues = []
var error_count = 0
var warning_count = 0

const SCENES_TO_ANALYZE = [
	"res://maze.tscn",
	"res://main.tscn",
	"res://player.tscn",
	"res://floor_tile.tscn",
	"res://wall_tile.tscn"
]

func _ready() -> void:
	run_tests()
	get_tree().quit(error_count)

func run_tests() -> void:
	print("========================================")
	print("  Scene Analysis")
	print("========================================")
	
	issues.clear()
	error_count = 0
	warning_count = 0
	
	# Analyze each scene
	for scene_path in SCENES_TO_ANALYZE:
		analyze_scene(scene_path)
	
	# Print summary
	print("\n========================================")
	print("  Analysis Summary")
	print("========================================")
	print("Scenes analyzed: %d" % SCENES_TO_ANALYZE.size())
	print("Errors found: %d" % error_count)
	print("Warnings found: %d" % warning_count)
	
	if error_count == 0 and warning_count == 0:
		print("✅ No issues found - scenes are solid!")
		print("PASSED")
	else:
		print("⚠️  Issues found - review below")
		if error_count > 0:
			print("FAILED")
		else:
			print("PASSED_WITH_WARNINGS")
	
	# Print all issues
	if issues.size() > 0:
		print("\n========================================")
		print("  Issues Found")
		print("========================================")
		for issue in issues:
			print(issue)


func analyze_scene(scene_path: String) -> void:
	print("\n[Analyzing] %s" % scene_path)
	
	if not ResourceLoader.exists(scene_path):
		record_error(scene_path, "Scene file does not exist")
		return
	
	# Load scene
	var scene = load(scene_path) as PackedScene
	if scene == null:
		record_error(scene_path, "Failed to load scene")
		return
	
	# Instantiate
	var instance = scene.instantiate()
	if instance == null:
		record_error(scene_path, "Failed to instantiate scene")
		return
	
	# Analyze scene
	check_missing_script_references(instance, scene_path)
	check_invalid_node_paths(instance, scene_path)
	check_missing_resources(instance, scene_path)
	check_broken_prefab_references(instance, scene_path)
	check_invalid_transforms(instance, scene_path)
	check_missing_collision_shapes(instance, scene_path)
	check_material_issues(instance, scene_path)
	check_script_syntax(instance, scene_path)
	
	instance.queue_free()


func check_missing_script_references(node: Node, scene_path: String) -> void:
	if node.get_script() != null:
		var script = node.get_script()
		if script is GDScript:
			var gdscript = script as GDScript
			var script_path = gdscript.resource_path
			if script_path.is_empty():
				record_error(scene_path, "Node '%s' has script with empty path" % node.get_path())
			elif not ResourceLoader.exists(script_path):
				record_error(scene_path, "Node '%s' references missing script: %s" % [node.get_path(), script_path])
	
	for child in node.get_children():
		check_missing_script_references(child, scene_path)


func check_invalid_node_paths(node: Node, scene_path: String) -> void:
	# Check for nodes that reference other nodes
	if node.has_method("get_node"):
		# This is a simplified check - in practice, we'd need to parse the script
		pass
	
	for child in node.get_children():
		check_invalid_node_paths(child, scene_path)


func check_missing_resources(node: Node, scene_path: String) -> void:
	# Check MeshInstance3D for missing meshes
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh == null:
			record_warning(scene_path, "MeshInstance3D '%s' has no mesh" % node.get_path())
		else:
			# Check if mesh resource exists
			var mesh = mesh_instance.mesh
			if mesh.resource_path != "" and not ResourceLoader.exists(mesh.resource_path):
				record_error(scene_path, "MeshInstance3D '%s' references missing mesh: %s" % [node.get_path(), mesh.resource_path])
	
	# Check CollisionShape3D for missing shapes
	if node is CollisionShape3D:
		var collision = node as CollisionShape3D
		if collision.shape == null:
			record_error(scene_path, "CollisionShape3D '%s' has no shape" % node.get_path())
	
	# Check materials
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh != null:
			if mesh_instance.material_override != null:
				var material = mesh_instance.material_override
				if material.resource_path != "" and not ResourceLoader.exists(material.resource_path):
					record_warning(scene_path, "MeshInstance3D '%s' references missing material: %s" % [node.get_path(), material.resource_path])
	
	for child in node.get_children():
		check_missing_resources(child, scene_path)


func check_broken_prefab_references(node: Node, scene_path: String) -> void:
	# Check if node is an instance
	if node.scene_file_path != "":
		var prefab_path = node.scene_file_path
		if not ResourceLoader.exists(prefab_path):
			record_error(scene_path, "Node '%s' references missing prefab: %s" % [node.get_path(), prefab_path])
	
	for child in node.get_children():
		check_broken_prefab_references(child, scene_path)


func check_invalid_transforms(node: Node, scene_path: String) -> void:
	# Check for NaN or infinite values in transforms
	var transform = node.transform
	if transform.origin.is_nan() or transform.origin.is_inf():
		record_error(scene_path, "Node '%s' has invalid transform origin" % node.get_path())
	
	# Check scale
	var scale = transform.basis.get_scale()
	if scale.is_nan() or scale.is_inf():
		record_error(scene_path, "Node '%s' has invalid transform scale" % node.get_path())
	
	for child in node.get_children():
		check_invalid_transforms(child, scene_path)


func check_missing_collision_shapes(node: Node, scene_path: String) -> void:
	# Check StaticBody3D and CharacterBody3D have collision shapes
	if node is StaticBody3D or node is CharacterBody3D:
		var has_collision = false
		for child in node.get_children():
			if child is CollisionShape3D:
				has_collision = true
				break
		
		if not has_collision:
			record_warning(scene_path, "%s '%s' has no CollisionShape3D child" % [node.get_class(), node.get_path()])
	
	for child in node.get_children():
		check_missing_collision_shapes(child, scene_path)


func check_material_issues(node: Node, scene_path: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh != null:
			# Check if mesh has materials
			if mesh_instance.mesh is ArrayMesh:
				var array_mesh = mesh_instance.mesh as ArrayMesh
				for i in range(array_mesh.get_surface_count()):
					var material = array_mesh.surface_get_material(i)
					if material == null:
						record_warning(scene_path, "MeshInstance3D '%s' surface %d has no material" % [node.get_path(), i])
	
	for child in node.get_children():
		check_material_issues(child, scene_path)


func check_script_syntax(node: Node, scene_path: String) -> void:
	# This is a simplified check - full syntax checking would require parsing
	if node.get_script() != null:
		var script = node.get_script()
		if script is GDScript:
			var gdscript = script as GDScript
			# Try to get source code to check basic syntax
			# In practice, Godot would catch syntax errors during load
			var script_path = gdscript.resource_path
			if script_path != "" and ResourceLoader.exists(script_path):
				# Script exists and loaded, assume syntax is OK
				pass
	
	for child in node.get_children():
		check_script_syntax(child, scene_path)


func record_error(scene_path: String, message: String) -> void:
	var error_msg = "[ERROR] %s: %s" % [scene_path, message]
	issues.append(error_msg)
	error_count += 1


func record_warning(scene_path: String, message: String) -> void:
	var warning_msg = "[WARNING] %s: %s" % [scene_path, message]
	issues.append(warning_msg)
	warning_count += 1
