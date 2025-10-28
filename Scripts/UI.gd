extends CanvasLayer

@onready var money_label = $Control/topLeft/VBoxContainer/HBoxContainer/Money/Label
@onready var month_label = $Control/topLeft/VBoxContainer/HBoxContainer/Time/Label
@onready var tool_icon = $Control/right/inventory/Drain
@onready var phase_panel = $Control/topLeft/Phase
@onready var phase_icon = $Control/topLeft/Phase/TextureRect
@onready var flood_bar = $Control/ProgressBar

func update_ui(money, month, tool, phase, flood):
	money_label.text = "₱" + str(money)
	month_label.text = "Month: " + str(month)
	
	if tool=="drain":
		tool_icon = $Control/right/inventory/Drain
		
		var tool_style = StyleBoxFlat.new()
		var green_color = Color(0.0, 1.0, 0.0) 
		tool_style.set_border_color(green_color) 
		tool_icon.add_theme_stylebox_override("panel", tool_style)
	
	#var phase_style = StyleBoxFlat.new()
	#var storm_color = Color(38, 71, 122)
	#phase_style.set_border_color(storm_color) 
	#phase_panel.add_theme_stylebox_override("panel", phase_style)
	
	print(phase)
	
	flood_bar.value = flood
