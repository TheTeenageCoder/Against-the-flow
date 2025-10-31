extends Node3D

@export var camera: Camera3D
@export var ghost_scene: PackedScene

@onready var map = $"../../map"
@onready var gameManager = get_node("..")

@onready var layer1 = $"../../map/Layer0"

var grid_pos
var ghost: Node3D

var orientation = Vector3(0,0,0)

func update_obj(tool):
	match tool:
		"drain":
			ghost_scene = load("res://Scenes/drain.tscn")
		"straight":
			ghost_scene = load("res://Scenes/pipes/normal/straight.tscn")
		"cross":
			ghost_scene = load("res://Scenes/pipes/normal/cross.tscn")
		"tshape":
			ghost_scene = load("res://Scenes/pipes/normal/tshape.tscn")
		"lshape":
			ghost_scene = load("res://Scenes/pipes/normal/lshape.tscn")
		"open":
			ghost_scene = load("res://Scenes/pipes/normal/open.tscn")
					
	var ghosts = get_children()
	for parts in ghosts:
		parts.queue_free()
		
	if ghost_scene != null:
		ghost = ghost_scene.instantiate()
		ghost.transparency = 0.8
		add_child(ghost)
	
	orientation = Vector3(0,0,0)

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

	if result and gameManager.current_tool != "none" and gameManager.current_tool != "pipe":
		if Input.is_action_just_released("rotate"): 
			orientation += Vector3(0, deg_to_rad(90), 0)
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
			#var is_occupied = is_tile_occupied()

			#var style = StandardMaterial3D.new()
			#if is_occupied:
		#		style.albedo_color = Color(255,0,0)
		#	else:
		#		style.albedo_color = Color(0.0, 255.014, 0.0, 1.0)
				
		#	ghost.set_surface_override_material(0, style)

			ghost.global_position = grid_pos
			ghost.rotation = orientation
			var pipes = ["straight", "cross", "tshape", "lshape", "open"]
			if pipes.has(gameManager.current_tool):
				ghost.position.y -= 0.425
		else:
			ghost.visible = false
	else:
		ghost.visible = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		place_obj(gameManager.current_tool, grid_pos)
			
@export var drain_scene: PackedScene
@export var pipe_scene: PackedScene

@onready var notif = get_node("../../UI/notifManager")

var occupied_tiles = {} 

func is_tile_occupied() -> bool:
	var key = str(grid_pos)
	return occupied_tiles.has(key)

func occupy_tile():
	var key = str(grid_pos)
	occupied_tiles[key] = true

func free_tile():
	var key = str(grid_pos)
	occupied_tiles.erase(key)

func place_obj(tool, pos):
	if is_tile_occupied():
		print("Tile already occupied!")
		return
	if tool == "none":
		return
		
	var new_obj
	var pipes = ["straight", "cross", "tshape", "lshape"]
	
	match tool:
		"drain":
			if layer1.visible == false:
				notif.notify("Object can only be placed on the surface", Color.RED)
				return
				
			if gameManager.money < gameManager.objValues.drain:
				notif.notify("Not enough money!", Color.RED)
				return

			gameManager.money -= gameManager.objValues.drain
			gameManager.total_drains += 1
			gameManager.working_drains += 1
			gameManager._update_ui()
			
			if drain_scene == null:
				drain_scene = preload("res://Scenes/drain.tscn")

			new_obj = drain_scene.instantiate()
			
			var placed_objects = get_node("../../map/Placed/under")
			var posUnder = Vector3(pos.x, -0.02437, pos.z)
	
			for child in placed_objects.get_children():
				if child is MeshInstance3D: 
					if child.global_position.is_equal_approx(posUnder):
						var replaced = load("res://Scenes/pipes/drain/" + child.name + ".tscn").instantiate()
						placed_objects.add_child(replaced)

						replaced.global_position = posUnder - Vector3(0,0.075,0)
						child.queue_free()
						
						
		"pipe":
			notif.notify("Select the type of pipe first", Color.RED)
			return
		"straight":
			if layer1.visible == true:
				notif.notify("Object can only be placed underground", Color.RED)
				return
				
			if gameManager.money < gameManager.objValues.pipe:
				notif.notify("Not enough money!", Color.RED)
				return
				
			gameManager.money -= gameManager.objValues.pipe
			gameManager._update_ui()
			
			pipe_scene = load("res://Scenes/pipes/normal/straight.tscn")

			new_obj = pipe_scene.instantiate()
		"cross":
			if layer1.visible == true:
				notif.notify("Object can only be placed underground", Color.RED)
				return
			
			if gameManager.money < gameManager.objValues.pipe:
				notif.notify("Not enough money!", Color.RED)
				return

			gameManager.money -= gameManager.objValues.pipe
			gameManager._update_ui()
			
			pipe_scene = load("res://Scenes/pipes/normal/cross.tscn")

			new_obj = pipe_scene.instantiate()
		"tshape":
			if layer1.visible == true:
				notif.notify("Object can only be placed underground", Color.RED)
				return
				
			if gameManager.money < gameManager.objValues.pipe:
				notif.notify("Not enough money!", Color.RED)
				return

			gameManager.money -= gameManager.objValues.pipe
			gameManager._update_ui()
			
			pipe_scene = load("res://Scenes/pipes/normal/tshape.tscn")

			new_obj = pipe_scene.instantiate()
		"lshape":
			if layer1.visible == true:
				notif.notify("Object can only be placed underground", Color.RED)
				return
				
			if gameManager.money < gameManager.objValues.pipe:
				notif.notify("Not enough money!", Color.RED)
				return 

			gameManager.money -= gameManager.objValues.pipe
			gameManager._update_ui()
			
			pipe_scene = load("res://Scenes/pipes/normal/lshape.tscn")

			new_obj = pipe_scene.instantiate()
		
	var posText = str(Vector3(pos.x, 0.105, pos.z))
		
	if occupied_tiles.has(posText):
		if pipes.has(tool):
			pipe_scene = load("res://Scenes/pipes/drain/" + tool + ".tscn")
		
		if pipe_scene != null:
			new_obj = pipe_scene.instantiate()
		
	if layer1.visible:
		get_node("../../map/Placed/surface").add_child(new_obj)
	else:
		get_node("../../map/Placed/under").add_child(new_obj)
	
	var tween = create_tween()
	new_obj.scale = Vector3.ZERO
	var finalScale
	if tool == "drain":
		new_obj.global_position = pos
		finalScale = Vector3(0.01, 0.01, 0.01)
	elif pipes.has(tool):
		new_obj.global_position = pos-Vector3(0,0.425,0)
		finalScale = Vector3.ONE
		print(new_obj.global_position)
	
	if pipes.has(tool) and pipe_scene.resource_path.contains("res://Scenes/pipes/drain/"):
		new_obj.global_position = pos-Vector3(0,0.5,0)
		finalScale = Vector3.ONE
	
	new_obj.rotation = orientation
		
	tween.tween_property(new_obj, "scale", finalScale , 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	occupy_tile()
