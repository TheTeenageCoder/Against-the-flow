extends Panel

const POP_DURATION = 0.095
const STAGGER_TIME = 0.003
const GRID_MOVE_DURATION = 0.485
const GRID_MOVE_AMOUNT = 0.2
const MIN_SCALE = Vector3(0.001, 0.001, 0.001)

var is_animating = false

func _on_button_pressed():
	if is_animating:
		return
	
	_toggle_layer_animated()

func _toggle_layer_animated():
	is_animating = true
	
	var layer = get_node("../../../../map/Layer0")
	var layerAssets = get_node("../../../../map/Assets")
	var placedSurface = get_node("../../../../map/Placed/surface")
	var grid = get_node("../../../../map/gridPlane")
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
		placedSurface.visible = false
		
		total_stagger_time = _start_staggered_animation(
			nodes_to_animate, Vector3(1,0.2,1), MIN_SCALE, POP_DURATION, false
		)
		
		grid_tween.tween_property(grid, "position", grid.position - Vector3(0, GRID_MOVE_AMOUNT, 0), GRID_MOVE_DURATION)
		
		await get_tree().create_timer(total_stagger_time).timeout
		await grid_tween.finished
		
		layer.visible = false
	else:
		label.text = "L1"
		layer.visible = true

			
		total_stagger_time = _start_staggered_animation(
			nodes_to_animate, MIN_SCALE, Vector3(1,0.2,1), POP_DURATION, true
		)
		
		grid_tween.tween_property(grid, "position", grid.position + Vector3(0, GRID_MOVE_AMOUNT, 0), GRID_MOVE_DURATION)

		await get_tree().create_timer(total_stagger_time).timeout
		await grid_tween.finished
		
		layerAssets.visible = true
		placedSurface.visible = true
	
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
