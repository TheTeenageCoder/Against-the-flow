extends CanvasLayer

@onready var money_label = $Control/topLeft/VBoxContainer/HBoxContainer/Money/Label
@onready var month_label = $Control/topLeft/VBoxContainer/HBoxContainer/Time/Label
@onready var tool_icon	

@onready var phase_panel = $Control/topLeft/Phase
@onready var phase_icon = $Control/topLeft/Phase/TextureRect
@onready var flood_bar = $Control/ProgressBar

func update_ui(money, month, tool, phase, flood):
	money_label.text = "₱" + str(money)
	month_label.text = "Month: " + str(month)
	
	print(tool)
	match tool:
		"drain":
			tool_icon = $Control/right/inventory/Drain
		"pipes":
			tool_icon = $Control/right/inventory/Pipes
		"demolish":
			tool_icon = $Control/right/inventory/Demolish
		"upgrade":
			tool_icon = $Control/right/inventory/Upgrade
		"fix":
			tool_icon = $Control/right/inventory/Fix

	#reset
	for panel in get_node("Control/right/inventory").get_children():
		var tool_style = panel.get_theme_stylebox("panel").duplicate()
		var white = Color(1.0, 1.0, 1.0, 1.0) 
		tool_style.set_border_color(white) 
		panel.add_theme_stylebox_override("panel", tool_style)	
		
	if tool != "none":
		var tool_style = tool_icon.get_theme_stylebox("panel").duplicate()
		var green_color = Color(0.0, 1.0, 0.0) 
		tool_style.set_border_color(green_color) 
		tool_icon.add_theme_stylebox_override("panel", tool_style)
	
	#var phase_style = StyleBoxFlat.new()
	#var storm_color = Color(38, 71, 122)
	#phase_style.set_border_color(storm_color) 
	#phase_panel.add_theme_stylebox_override("panel", phase_style)
	
	print(phase)
	
	flood_bar.value = flood
