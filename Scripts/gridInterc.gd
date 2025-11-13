extends Node3D

@export var camera: Camera3D
@export var ghost_scene: PackedScene

@onready var map = $"../../map"
@onready var gameManager = get_node("..")
@onready var layer1 
@onready var toolSFX = $"../../UI/Control/toolSFX"

var grid_pos
var ghost: Node3D

var orientation = Vector3(0,0,0)

func update_obj(tool):
	var pipes = ["straight", "cross", "tshape", "lshape", "open"]
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
		"demolish":
			ghost_scene = load("res://Scenes/demolish.tscn")
		"upgrade":
			ghost_scene = load("res://Scenes/upgrade.tscn")
			
	var ghosts = get_children()
	for parts in ghosts:
		parts.queue_free()
		
	if ghost_scene != null:
		ghost = ghost_scene.instantiate()
		if tool == "drain":
			ghost.transparency = 0.8
		elif pipes.has(tool):
			ghost.get_node("mesh").transparency = 0.8
			for p in ghost.get_children():
				if p is Area3D:
					p.monitoring = false
					p.monitorable = false

		add_child(ghost)
	
	orientation = Vector3(0,0,0)

var save_path := "user://data.json"

var act

func load_game():
	if not FileAccess.file_exists(save_path):
		print("⚠ No save file found.")
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json_text)
	if result != null:
		act = result
	else:
		print("❌ Failed to parse JSON")

func _ready():
	load_game()
	set_process(false)
	if act != -1:
		while not gameManager.is_loaded:
			await get_tree().process_frame
		set_process(true)
		
		for child in  $"../..".get_children():
			if child is Node3D:
				map = child
		layer1 = map.get_node("Layer0")
	
	if camera == null:
		camera = get_viewport().get_camera_3d()
	
	map.get_node("Placed").check_connection()
		
	update_obj(gameManager.current_tool)
	
var has_duplicated := false
var last_upgrade_pos := Vector3.ZERO

func _process(_delta):
	if not camera or not ghost:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
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
			ghost.rotation = orientation

			var pipes = ["straight", "cross", "tshape", "lshape", "open"]
			if pipes.has(gameManager.current_tool):
				ghost.position.y -= 0.425
			
			if gameManager.current_tool == "upgrade" and layer1.visible == false:
				if occupied_tiles.has(str(Vector3(grid_pos.x, 0.40063, grid_pos.z))):
					if not has_duplicated or grid_pos != last_upgrade_pos:
						has_duplicated = true
						last_upgrade_pos = grid_pos

						# clear old duplicates
						for part in get_children():
							if part.name == "ghostDupe":
								part.queue_free()

						for part in map.get_node("Placed/under").get_children():
							if part.name != "output":
								var ghostDupe = ghost.duplicate()
								ghostDupe.name = "ghostDupe"
								$"../ghostDupes".add_child(ghostDupe)
								ghostDupe.global_position = Vector3(part.global_position.x, grid_pos.y, part.global_position.z)
				else:
					has_duplicated = false
					for part in $"../ghostDupes".get_children():
						part.free()
		else:
			ghost.visible = false
	else:
		ghost.visible = false
		has_duplicated = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and gameManager.current_tool != "none" and gameManager.current_tool != "pipe":
		if not gameManager.in_dialouge:
			place_obj(gameManager.current_tool, grid_pos)
			
@export var drain_scene: PackedScene
@export var pipe_scene: PackedScene

@onready var notif = get_node("../../UI/notifManager")

var occupied_tiles = {}

func is_tile_occupied(tile = str(grid_pos)) -> bool:
	return occupied_tiles.has(tile)

func occupy_tile():
	var key = str(grid_pos)
	occupied_tiles[key] = true

func free_tile(tile = str(grid_pos)):
	occupied_tiles.erase(tile)

func place_obj(tool, pos: Vector3):
	if is_tile_occupied():
		if tool != "demolish":
			notif.notify("Tile already occupied", Color.RED)
			toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
			toolSFX.play()
			return
	
	if layer1.visible == true:
		for part in map.get_node("Assets").get_children():
			if part.global_position == Vector3(pos.x, 0.3, pos.z):
				notif.notify("Tile contains an object", Color.RED)
				toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
				toolSFX.play()
				return
	else:
		for part in map.get_node("Assets").get_children():
			if part.global_position == Vector3(pos.x, -0.1, pos.z):
				notif.notify("Tile contains an object", Color.RED)
				toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
				toolSFX.play()
				return
		
	var new_obj
	var pipes = ["straight", "cross", "tshape", "lshape"]
	if pipes.has(tool):
		if gameManager.needPipeDialouge:
			gameManager.dialougeIndex += 1
			print("From Pipe placing: " + str(gameManager.dialougeIndex))
			gameManager.needPipeDialouge = false

	match tool:
		"drain":
			if layer1.visible == false:
				notif.notify("Object can only be placed on the surface", Color.RED)
				toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
				toolSFX.play()
				return
				
			if gameManager.money < gameManager.objValues.drain:
				notif.notify("Not enough money!", Color.RED)
				return

			gameManager.money -= gameManager.objValues.drain
			#gameManager.drains[str(Vector3(pos.x,0.305,pos.y))] = true
			
			if drain_scene == null:
				drain_scene = preload("res://Scenes/drain.tscn")

			new_obj = drain_scene.instantiate()
			
			if gameManager.needDrainDialouge:
				gameManager.dialougeIndex += 1
				print("From drain placing: " + str(gameManager.dialougeIndex))
				gameManager.needDrainDialouge = false
			
				
			var placed_objects = map.get_node("Placed/under")
			var posUnder = Vector3(pos.x, -0.02437, pos.z)
			
			for child in placed_objects.get_children():
				if child is Node3D:
					if child.global_position.is_equal_approx(posUnder):
						var objName
						var formalName
						match child.get_node("mesh").mesh.resource_path:
							"res://Models/Pipes/Pipe - Cross.obj", "res://Models/Pipes/Upgraded Pipe - Cross.obj":
								objName = "cross"
								formalName = "Cross"
							"res://Models/Pipes/Pipe - Straight.obj", "res://Models/Pipes/Upgraded Pipe - Straight.obj":
								objName = 'straight'
								formalName = "Straight"
							"res://Models/Pipes/Pipe - T-shape.obj", "res://Models/Pipes/Upgraded Pipe - T-Shape.obj":
								objName = "tshape"
								formalName = "T-Shape"
							"res://Models/Pipes/Pipe - L-shape.obj", "res://Models/Pipes/Upgraded Pipe - L-Shape.obj":
								objName = "lshape"
								formalName = "L-Shape"

						var replaced = load("res://Scenes/pipes/drain/" + objName + ".tscn").instantiate()
						
						if gameManager.pipesUpgraded:
							replaced.get_node("mesh").mesh = load("res://Models/Pipes/Drain Pipe/Upgraded Drain Pipe - "+formalName+".obj.obj")
						placed_objects.add_child(replaced)

						replaced.global_position = posUnder - Vector3(0,0.075,0)
						replaced.rotation = child.rotation
						replaced.visible = false
						child.queue_free()
		"pipe":
			notif.notify("Select the type of pipe first", Color.RED)
			toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
			toolSFX.play()
			return
		"straight":
			if layer1.visible == true:
				notif.notify("Object can only be placed underground", Color.RED)
				toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
				toolSFX.play()
				return
				
			if gameManager.money < gameManager.objValues.pipe:
				notif.notify("Not enough money!", Color.RED)
				return
				
			gameManager.money -= gameManager.objValues.pipe
			
			pipe_scene = load("res://Scenes/pipes/normal/straight.tscn")

			new_obj = pipe_scene.instantiate()
		"cross":
			if layer1.visible == true:
				notif.notify("Object can only be placed underground", Color.RED)
				toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
				toolSFX.play()
				return
			
			if gameManager.money < gameManager.objValues.pipe:
				notif.notify("Not enough money!", Color.RED)
				return

			gameManager.money -= gameManager.objValues.pipe
			
			pipe_scene = load("res://Scenes/pipes/normal/cross.tscn")

			new_obj = pipe_scene.instantiate()
		"tshape":
			if layer1.visible == true:
				notif.notify("Object can only be placed underground", Color.RED)
				toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
				toolSFX.play()
				return
				
			if gameManager.money < gameManager.objValues.pipe:
				notif.notify("Not enough money!", Color.RED)
				return

			gameManager.money -= gameManager.objValues.pipe
			
			pipe_scene = load("res://Scenes/pipes/normal/tshape.tscn")
			 

			new_obj = pipe_scene.instantiate()
		"lshape":
			if layer1.visible == true:
				notif.notify("Object can only be placed underground", Color.RED)
				toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
				toolSFX.play()
				return
				
			if gameManager.money < gameManager.objValues.pipe:
				notif.notify("Not enough money!", Color.RED)
				return

			gameManager.money -= gameManager.objValues.pipe
			
			pipe_scene = load("res://Scenes/pipes/normal/lshape.tscn")

			new_obj = pipe_scene.instantiate()
		"demolish":
			var area = get_node("demolish/Area3D")
			var bodies = area.get_overlapping_bodies()
			if bodies.is_empty():
				notif.notify("Hover over an object", Color.RED)
				toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
				toolSFX.play()
				return

			var target = bodies[0]
			if bodies.size() > 1:
				target = bodies[0] if bodies[0].global_position.y < bodies[1].global_position.y else bodies[1]

			var current = target
			while current and current.get_parent() and not current.get_parent().name in ["surface", "under"]:
				current = current.get_parent()

			if current and current.get_parent() and current.get_parent().name in ["surface", "under"]:
				if current.get_parent().name == "surface":
					free_tile(str(Vector3(current.global_position.x, 0.305, current.global_position.z)))
				else:
					free_tile(str(Vector3(current.global_position.x, 0.40063, current.global_position.z)))
				
				if current is MeshInstance3D :
					gameManager.money += gameManager.objValues.drain*0.8
				else:
					gameManager.money += gameManager.objValues.pipe*0.8

				@warning_ignore("confusable_local_declaration")
				var tween = create_tween()
				tween.tween_property(current, "scale", current.scale * 1.4, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween.tween_property(current, "scale", Vector3.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tween.tween_callback(Callable(current, "queue_free"))
				
				toolSFX.stream = load("res://Sounds/Demolish.mp3")
				toolSFX.play()
				
				if gameManager.needDemolishDialouge:
					gameManager.dialougeIndex += 1
					print("From demolish: " + str(gameManager.dialougeIndex))
					gameManager.needDemolishDialouge = false
			else:
				print("Could not find root for:", target.name)

			return
		"upgrade":
			if layer1.visible == true:
				if occupied_tiles.has(str(Vector3(pos.x, 0.305, pos.z))):
					var area = get_node("upgrade/Area3D")
					var bodies = area.get_overlapping_bodies()
					if bodies.is_empty():
						notif.notify("Hover over an object", Color.RED)
						return

					var target = bodies[0]
					if bodies.size() > 1:
						target = bodies[0] if bodies[0].global_position.y < bodies[1].global_position.y else bodies[1]

					var current = target
					while current and current.get_parent() and not current.get_parent().name in ["surface", "under"]:
						current = current.get_parent()
					#var currentV2pos = Vector2(current.global_position.x, current.global_position.z)
					if gameManager.upgradedDrains.has(Vector2(pos.x, pos.z)):
						notif.notify("Drain already upgraded", Color.RED)
						return
						
					if current and current.get_parent() and current.get_parent().name in ["surface", "under"]:
						if current is MeshInstance3D:
							@warning_ignore("confusable_local_declaration")
							var tween = create_tween()
							tween.tween_property(current, "scale", current.scale * 0.8, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
							tween.tween_property(current, "scale", current.scale * 1.2, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
					else:
						print("Could not find root for:", target.name)
						
					gameManager.upgradedDrains.append(Vector2(pos.x, pos.z))
					gameManager.money -= gameManager.objValues.drain*1.1
			else:
				if gameManager.pipesUpgraded:
					notif.notify("Pipes are already upgraded", Color.RED)
					toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
					toolSFX.play()
					return
				for part in $"../ghostDupes".get_children():
					var area = part.get_node("Area3D")
					var bodies = area.get_overlapping_bodies()
					if bodies.is_empty():
						notif.notify("Hover over an object", Color.RED)
						toolSFX.stream = load("res://Sounds/Cannot Place.mp3")
						toolSFX.play()
						return
						
					var target = bodies[0]
					if bodies.size() > 1:
						target = bodies[0] if bodies[0].global_position.y < bodies[1].global_position.y else bodies[1]

					var current = target
					while current and current.get_parent() and not current.get_parent().name in ["surface", "under"]:
						current = current.get_parent()

					
					if current and current.get_parent() and current.get_parent().name in ["surface", "under"]:
						if current.get_node("mesh"):
							var meshRes = current.get_node("mesh").mesh.resource_path
							print(meshRes)
							var isDrain = true  if "Drain" in meshRes else false
							var meshType
							var newMesh
							if isDrain:
								meshType = meshRes.trim_suffix(".obj").trim_prefix("res://Models/Pipes/Drain Pipe/Drain Pipe - ")
								newMesh = load("res://Models/Pipes/Drain Pipe/Upgraded Drain Pipe - "+meshType+".obj.obj")
							else:
								meshType = meshRes.trim_suffix(".obj").trim_prefix("res://Models/Pipes/Pipe - ")
								newMesh = load("res://Models/Pipes/Upgraded Pipe - "+meshType+".obj")
							
							current.get_node("mesh").mesh = newMesh
							part.queue_free()
							gameManager.money -= (bodies.size()+1)*gameManager.objValues["pipe"]+1000000
					else:
						print("Could not find root for:", target.name)
						
				gameManager.dialougeIndex += 1
				print("From upgrade: " + str(gameManager.dialougeIndex))
				gameManager.pipesUpgraded = true
				gameManager.objValues.pipe *= 2
			toolSFX.stream = load("res://Sounds/Demolish.mp3")
			toolSFX.play()
			return

	toolSFX.stream = load("res://Sounds/Place Down.mp3")
	toolSFX.play()
	var posText = str(Vector3(pos.x, 0.305, pos.z))
		
	if occupied_tiles.has(posText):
		if pipes.has(tool):
			pipe_scene = load("res://Scenes/pipes/drain/" + tool + ".tscn")
		if pipe_scene != null:
			new_obj = pipe_scene.instantiate()
		
	if layer1.visible:
		map.get_node("Placed/surface").add_child(new_obj)
	else:
		if gameManager.pipesUpgraded:
			if new_obj.get_node("mesh"):
				var meshRes = new_obj.get_node("mesh").mesh.resource_path
				var isDrain = true  if "Drain" in meshRes else false
				var meshType
				var newMesh
				if isDrain:
					meshType = meshRes.trim_suffix(".obj").trim_prefix("res://Models/Pipes/Drain Pipe/Drain Pipe - ")
					newMesh = load("res://Models/Pipes/Drain Pipe/Upgraded Drain Pipe - "+meshType+".obj.obj")
				else:
					meshType = meshRes.trim_suffix(".obj").trim_prefix("res://Models/Pipes/Pipe - ")
					newMesh = load("res://Models/Pipes/Upgraded Pipe - "+meshType+".obj")
				new_obj.get_node("mesh").mesh = newMesh
		map.get_node("Placed/under").add_child(new_obj)
	
	var tween = create_tween()
	new_obj.scale = Vector3.ZERO
	var finalScale
	if tool == "drain":
		new_obj.global_position = pos
		finalScale = Vector3(0.01, 0.01, 0.01)
		#new_obj.transparency = 0.5
	elif pipes.has(tool):
		new_obj.global_position = pos-Vector3(0,0.425,0)
		finalScale = Vector3.ONE
		#print(new_obj.global_position)
		#new_obj.get_node("mesh").transparency = 0.5
	if pipes.has(tool) and pipe_scene.resource_path.contains("res://Scenes/pipes/drain/"):
		new_obj.global_position = pos-Vector3(0,0.5,0)
		finalScale = Vector3.ONE
	
	new_obj.rotation = orientation
		
	tween.tween_property(new_obj, "scale", finalScale , 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	occupy_tile()
	#await tween.finished

	#$"../../map/Placed".check_connection()
	#$"../../map/Placed".process_all_drains()
	#$"../../map/Placed".process_all_pipes()
