extends Node3D

@export var camera: Camera3D
@export var ghost_scene: PackedScene

@onready var map = $"../../map"
@onready var gameManager = get_node("..")

var grid_pos
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
			var is_occupied = is_tile_occupied()
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

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#var grid_pos = ghostBlocks.grid_pos
		if gameManager.current_tool == "drain":
			print("Clicked grid:", grid_pos)
			place_drain(grid_pos)
			
@export var drain_scene: PackedScene

var occupied_tiles = {}  # Dictionary for quick lookup: {"x_z_key": true}

func is_tile_occupied() -> bool:
	var key = str(grid_pos)
	return occupied_tiles.has(key)

func occupy_tile():
	var key = str(grid_pos)
	occupied_tiles[key] = true

func free_tile():
	var key = str(grid_pos)
	occupied_tiles.erase(key)

func place_drain(pos):
	if is_tile_occupied():
		print("Tile already occupied!")
		return

	if gameManager.money < 300000:
		print("Not enough money!")
		return

	gameManager.money -= 300000
	gameManager.total_drains += 1
	gameManager.working_drains += 1
	gameManager._update_ui()
	
	if drain_scene == null:
		drain_scene = preload("res://Scenes/drain.tscn")
		
	var new_drain = drain_scene.instantiate()
	get_parent().add_child(new_drain)
	new_drain.global_position = pos
	
	var tween = create_tween()
	new_drain.scale = Vector3.ZERO
	tween.tween_property(new_drain, "scale", Vector3(0.01, 0.01, 0.01), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	occupy_tile()
