extends Node3D

var areas: Array[Area3D] = []

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
			return
			
	get_node("../../UI/Control/warning").visible = false
	print("safe")
