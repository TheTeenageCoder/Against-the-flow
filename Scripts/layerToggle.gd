extends Panel

const POP_DURATION = 0.2
var STAGGER_TIME = 0.0003
const GRID_MOVE_DURATION = 0.485
const GRID_MOVE_AMOUNT = 0.4
const MIN_SCALE = Vector3(0.001, 0.001, 0.001)

@onready var map
@onready var gameManager = $"../../../../GameManager"

var is_animating = false

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
	
	if act != -1:
		while not gameManager.is_loaded:
			await get_tree().process_frame
		
		for child in $"../../../..".get_children():
			if child is Node3D:
				map = child
	
		if map.get_node("gridPlane").mesh.size.x == 25:
			STAGGER_TIME = 0.00001

func _on_button_pressed():
	if is_animating:
		return
	_toggle_layer_animated()

func _toggle_layer_animated():
	is_animating = true
	
	var layer = map.get_node("Layer0")
	var layerAssets = map.get_node("Assets")
	var placedSurface = map.get_node("Placed/surface")
	var grid = map.get_node("gridPlane")
	var label = get_node("Label")
	
	if not is_instance_valid(layer) or not is_instance_valid(grid):
		is_animating = false
		return
		
	var nodes_to_animate = layer.get_children()
	
	var grid_tween = create_tween()
	grid_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var total_stagger_time = 0.0

	if layer.visible == true:
		label.text = "G1"
		layerAssets.visible = false
		for part in map.get_node("Placed/under").get_children():
			if part.name != "output":
				part.visible = true
		
		if gameManager.needLayerDialouge:
			gameManager.dialougeIndex += 1
			print("From layer interacton: " + str(gameManager.dialougeIndex))
			
			gameManager.needLayerDialouge = false
		for part in placedSurface.get_children():
			part.transparency = 0.7
		
		total_stagger_time = _start_staggered_animation(
			nodes_to_animate, Vector3(1,0.2,1), MIN_SCALE, POP_DURATION, false
		)
		
		grid_tween.tween_property(grid, "position", grid.position - Vector3(0, GRID_MOVE_AMOUNT, 0), GRID_MOVE_DURATION)
		
		await get_tree().create_timer(total_stagger_time).timeout
		await grid_tween.finished
		
		layer.visible = false
		map.get_node("flood").visible = false
	else:
		label.text = "L1"
		layer.visible = true
		if gameManager.phase == "storm":
			map.get_node("flood").visible = true
		for part in map.get_node("Placed/under").get_children():
			if part.name != "output":
				part.visible = false

		total_stagger_time = _start_staggered_animation(
			nodes_to_animate, MIN_SCALE, Vector3(1,0.4,1), POP_DURATION, true
		)
		
		grid_tween.tween_property(grid, "position", grid.position + Vector3(0, GRID_MOVE_AMOUNT, 0), GRID_MOVE_DURATION)
		
		await get_tree().create_timer(total_stagger_time).timeout
		await grid_tween.finished
		
		layerAssets.visible = true
		for part in placedSurface.get_children():
			part.transparency = 0
	
	is_animating = false

func _start_staggered_animation(nodes: Array, start_scale: Vector3, end_scale: Vector3, duration: float, is_showing: bool) -> float:
	nodes.shuffle()
	
	var total_time = duration + (nodes.size() * STAGGER_TIME)

	for i in range(nodes.size()):
		var cube = nodes[i]
		
		var delay = float(i) * STAGGER_TIME
		
		var cube_tween = cube.create_tween()
		
		var ease_type = Tween.EASE_OUT
		var trans_type = Tween.TRANS_ELASTIC
		
		if not is_showing:
			trans_type = Tween.TRANS_BACK
			ease_type = Tween.EASE_IN
		
		if delay > 0.0:
			cube_tween.tween_interval(delay)
		
		if is_showing:
			cube_tween.tween_callback(cube.set_visible.bind(true))
			cube_tween.tween_callback(cube.set_scale.bind(start_scale))
		
		cube_tween.tween_property(cube, "scale", end_scale, duration)\
			.set_trans(trans_type).set_ease(ease_type)

		if not is_showing:
			cube_tween.tween_callback(cube.set_visible.bind(false))
	
	return total_time
