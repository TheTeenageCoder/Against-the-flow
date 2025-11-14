extends Node3D

@onready var gameManager = get_node("../../GameManager")

var areas: Array[Area3D] = []

var connection_dialogue_triggered := false

func check_connection():
	process_all_drains()
	process_all_pipes()
	
	areas.clear()
	for area in $under/output.get_children():
		if area is Area3D:
			areas.append(area)
	
	for part in $under.get_children():
		if part is Node3D and part.name != "output":
			for area in part.get_children():
				if area is Area3D :
					areas.append(area)
	
	for part in areas:
		if part.monitoring and part.monitorable:
			var overlaps = part.get_overlapping_areas()
			if overlaps.size() == 0:
				get_node("../../UI/Control/warning").visible = true
				connection_dialogue_triggered = false 
				return
		else:
			get_node("../../UI/Control/warning").visible = true
			connection_dialogue_triggered = false 
			return
	
	get_node("../../UI/Control/warning").visible = false
	
	if gameManager.needConnectionDialouge and not connection_dialogue_triggered:
		gameManager.dialougeIndex += 1
		print("From Pipe Connection: " + str(gameManager.dialougeIndex))
		gameManager.needConnectionDialouge = false
		connection_dialogue_triggered = true

func process_all_drains():
	gameManager.drains.clear()
	for drain in get_node("surface").get_children():
		var pos = drain.global_position
		var posV2 = Vector2(pos.x, pos.z) 
		var power = 0.375 if gameManager.upgradedDrains.has(posV2) else 0.25
		var pipe = get_pipe_at_pos(posV2)
		if pipe and not pipe.has_node("warningIcon"):
			gameManager.drains[str(posV2)]= [true, power]
		
		
			
func process_all_pipes():
	gameManager.pipes.clear()
	gameManager.pipesMultiplier = 1.5 if gameManager.pipesUpgraded else 1.0
	for pipe in get_node("under").get_children():
		if pipe.name != "output":
			var pos = pipe.global_position
			var posV2 = Vector2(pos.x, pos.z) 
			gameManager.pipes[str(posV2)] = true 

func get_pipe_at_pos(v2_pos):
	for pipe in get_node("under").get_children():
		if pipe.name != "output":
			var pos = pipe.global_position
			var posV2 = Vector2(pos.x, pos.z) 
			if posV2 == v2_pos:
				return pipe
	return null # No pipe found
