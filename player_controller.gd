# player_controller.gd
# First-person player controller with WASD movement and mouse look
# Attach to CharacterBody3D node

extends CharacterBody3D

## Movement speed in meters per second
@export var speed: float = 5.0

## Mouse sensitivity for camera rotation
@export var mouse_sensitivity: float = 0.002

## Gravity value (from project settings)
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

## Reference to camera node
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	# Capture mouse cursor for first-person control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[PlayerController] Player ready, mouse captured")


func _input(event: InputEvent) -> void:
	# Handle mouse motion for camera rotation
	if event is InputEventMouseMotion:
		# Rotate player horizontally (Y-axis rotation)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera vertically (X-axis rotation)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		
		# Clamp vertical rotation to prevent camera flipping
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Allow ESC to release mouse cursor (for debugging)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Transform input direction to world space relative to player's rotation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Apply horizontal movement
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Smoothly stop when no input
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Move the character
	move_and_slide()
