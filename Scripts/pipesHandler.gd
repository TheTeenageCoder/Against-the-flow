extends Node3D

@onready var gameManager = get_node("../../GameManager")

var areas: Array[Area3D] = []

var connection_dialogue_triggered := false

func check_connection():
	areas.clear()
	for part in $under.get_children():
		if part is Node3D:
			for area in part.get_children():
				if area is Area3D:
					areas.append(area)
					
	for part in areas:
		var overlaps = part.get_overlapping_areas()
		if overlaps.size() == 0:
			get_node("../../UI/Control/warning").visible = true
			connection_dialogue_triggered = false  # reset trigger if disconnected
			return
			
	get_node("../../UI/Control/warning").visible = false
	process_all_drains()
	process_all_pipes()
	
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
		var power = 0.5 if gameManager.upgradedDrains.has(posV2) else 0.25
		if gameManager.pipes.has(str(posV2)):
			gameManager.drains[str(posV2)]= [true, power]
	#print(gameManager.drains)

func process_all_pipes():
	gameManager.pipes.clear()
	for pipe in get_node("under").get_children():
		if pipe.name != "output":
			var pos = pipe.global_position
			var posV2 = Vector2(pos.x, pos.z) 
			gameManager.pipesMultiplier = 1.5 if gameManager.pipesUpgraded else 1.0
			gameManager.pipes[str(posV2)]= true
	#print(gameManager.pipes)
