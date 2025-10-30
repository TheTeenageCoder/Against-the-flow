extends CanvasLayer

@onready var money_label = $Control/topLeft/VBoxContainer/HBoxContainer/Money/Label
@onready var month_label = $Control/topLeft/VBoxContainer/HBoxContainer/Time/Label
@onready var tool_icon	

@onready var pipeSelection = get_node("Control/rightPipes")
@onready var phase_panel = $Control/topLeft/Phase
@onready var phase_icon = $Control/topLeft/Phase/TextureRect
@onready var flood_bar = $Control/ProgressBar

func update_ui(money, month, tool, phase, flood):
	money_label.text = "₱" + str(money)
	month_label.text = "Month: " + str(month)
	
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
		
	#var phase_style = StyleBoxFlat.new()
	#var storm_color = Color(38, 71, 122)
	#phase_style.set_border_color(storm_color) 
	#phase_panel.add_theme_stylebox_override("panel", phase_style)
	
	print(phase)
	
	flood_bar.value = flood
