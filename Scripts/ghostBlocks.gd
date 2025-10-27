extends Node3D

@export var camera: Camera3D
@export var ghost_scene: PackedScene
var ghost: Node3D

func _ready():
	# Auto-find camera if not set manually
	if camera == null:
		camera = get_viewport().get_camera_3d()

	# Load ghost if not assigned in inspector
	if ghost_scene == null:
		ghost_scene = preload("res://ghostBlock.tscn")

	ghost = ghost_scene.instantiate()
	add_child(ghost)

func _process(_delta):
	if camera == null:
		return  # safety check

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		var pos = result.position
		var grid_pos = Vector3(round(pos.x), round(pos.y), round(pos.z))
		ghost.global_position = grid_pos
