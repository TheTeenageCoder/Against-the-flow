extends CanvasLayer

@onready var money_label = $Control/topLeft/VBoxContainer/HBoxContainer/Money/Label
@onready var month_label = $Control/topLeft/VBoxContainer/HBoxContainer/Time/Label
@onready var tool_icon	

@onready var pipeSelection = get_node("Control/rightPipes")
@onready var phase_panel = $Control/topLeft/Phase
@onready var phase_icon = $Control/topLeft/Phase/TextureRect
#@onready var flood_bar = $Control/ProgressBar

func update_ui(money, month, tool, phase):
	money_label.text = "₱" + str(money)
	var month_names = [
		"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]

	var month_index = int((month - 1) % 12)
	month_label.text = "Month: " + month_names[month_index]
	
	match tool:
		"drain":
			tool_icon = $Control/right/inventory/Drain
		"pipe":
			tool_icon = $Control/right/inventory/Pipe
		"demolish":
			tool_icon = $Control/right/inventory/Demolish
		"upgrade":
			tool_icon = $Control/right/inventory/Upgrade
		"fix":
			tool_icon = $Control/right/inventory/Fix
		"straight":
			tool_icon = $Control/rightPipes/selection/straight
		"cross":
			tool_icon = $Control/rightPipes/selection/cross
		"tshape":
			tool_icon = $Control/rightPipes/selection/tshape
		"lshape":
			tool_icon = $Control/rightPipes/selection/lshape

	#reset
	for panel in get_node("Control/right/inventory").get_children():
		var tool_style = panel.get_theme_stylebox("panel").duplicate()
		var white = Color(1.0, 1.0, 1.0, 1.0) 
		tool_style.set_border_color(white) 
		panel.add_theme_stylebox_override("panel", tool_style)	
	
	for panel in get_node("Control/rightPipes/selection").get_children():
		var tool_style = panel.get_theme_stylebox("panel").duplicate()
		var white = Color(1.0, 1.0, 1.0, 1.0) 
		tool_style.set_border_color(white) 
		panel.add_theme_stylebox_override("panel", tool_style)	
		
	pipeSelection.visible = false
		
	if tool != "none":
		var tool_style = tool_icon.get_theme_stylebox("panel").duplicate()
		var green_color = Color(0.0, 1.0, 0.0) 
		tool_style.set_border_color(green_color) 
		tool_icon.add_theme_stylebox_override("panel", tool_style)
	
	var pipes = ["pipe", "straight", "cross", "tshape", "lshape"]
	if pipes.has(tool):
		pipeSelection.visible = true
		
	var phase_style = phase_panel.get_theme_stylebox("panel").duplicate()
	if phase == "building":
		var building_color = Color(18.892, 18.892, 0.0)
		phase_style.set_bg_color(building_color) 
		phase_panel.add_theme_stylebox_override("panel", phase_style)
		phase_icon.texture = load("res://Sprites/Sun.svg")
	elif phase == "storm":
		var storm_color = Color.GRAY
		phase_style.set_bg_color(storm_color) 
		phase_panel.add_theme_stylebox_override("panel", phase_style)
		phase_icon.texture = load("res://Sprites/storm.svg")
	
	#flood_bar.value = flood
