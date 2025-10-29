extends Camera3D

@export var move_speed := 10.0
@export var zoom_speed := 5.0      # How fast the FOV changes
@export var min_fov := 30.0        # Smallest zoom-in (narrow)
@export var max_fov := 90.0        # Widest zoom-out

var target_fov := 70.0             # Default zoom level

func _ready():
	target_fov = fov

func _process(delta):
	_handle_movement(delta)
	
	# Smoothly interpolate to the target FOV
	fov = lerp(fov, target_fov, delta * zoom_speed)

func _unhandled_input(event):
	# Handle mouse wheel zoom using FOV
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_fov = clamp(target_fov - 5.0, min_fov, max_fov)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_fov = clamp(target_fov + 5.0, min_fov, max_fov)

func _handle_movement(delta):
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir.z -= 1
	if Input.is_action_pressed("move_back"):    dir.z += 1
	if Input.is_action_pressed("move_left"):    dir.x -= 1
	if Input.is_action_pressed("move_right"):   dir.x += 1

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	var forward := transform.basis.z
	var right := transform.basis.x
	var move := forward * dir.z + right * dir.x
	move.y = 0
	global_translate(move * move_speed * delta)
