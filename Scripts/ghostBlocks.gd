extends Node3D

@export var camera: Camera3D
@export var ghost_scene: PackedScene

@onready var gameManager = get_node("../../GameManager")
@onready var grid_pos

var ghost: Node3D

func update_obj(tool):
	if ghost_scene == null and tool != "none":
		if tool == "drain":
			ghost_scene = preload("res://Scenes/ghostDrain.tscn")

	if ghost_scene != null:
		ghost = ghost_scene.instantiate()
		add_child(ghost)

func _ready():
	if camera == null:
		camera = get_viewport().get_camera_3d()
	
	update_obj(gameManager.current_tool)


func _process(_delta):
	if not camera or not ghost:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result and gameManager.current_tool != "none":
		var normal: Vector3 = result.normal

		if normal.y > 0.7:
			var collider = result.collider
			var surface_height := 0.0
			if collider is MeshInstance3D:
				var aabb = collider.get_aabb()
				surface_height = aabb.size.y * collider.scale.y

			var ghost_height = ghost.scale.y
			var offset_y = (surface_height / 2.0) + (ghost_height / 2.0)
			var pos = result.position
			grid_pos = Vector3(round(pos.x), pos.y + offset_y, round(pos.z))

			ghost.visible = true
			ghost.global_position = grid_pos
			var is_occupied = gameManager.is_tile_occupied(grid_pos)
			ghost.visible = true

			if is_occupied:
				ghost.get_surface_override_material(0).duplicate().albedo_color = Color(255,0,0)
			else:
				ghost.get_surface_override_material(0).duplicate().albedo_color = Color(0.0, 255.014, 0.0, 1.0)

			ghost.global_position = grid_pos
		else:
			ghost.visible = false
	else:
		ghost.visible = false
