extends VBoxContainer

@onready var gameManager = get_node("../../../../GameManager")
@onready var UI = get_node("../../../../UI")
@onready var selectUI = UI.get_node("Control/leftSelect")

func _ready():
	for panel in get_children():
		if panel.has_node("TextureButton"):
			var button = panel.get_node("TextureButton")
			button.connect("pressed", Callable(self, "_on_button_pressed").bind(panel.name))
			
func format_number_abbreviated(number: int) -> String:
	
	var abs_number = abs(number)
	var polarity = "" if number >= 0 else "-"
	
	if abs_number < 1000:
		return str(number)
	
	const SUFFIXES = ["K", "M", "B"]

	var index = -1
	var formatted_number = float(abs_number)
	
	while formatted_number >= 1000 and index < len(SUFFIXES) - 1:
		formatted_number /= 1000.0
		index += 1

	var precision = 1 if formatted_number < 10 else 0
	
	return polarity + str(formatted_number).format("%.{p}f").replace("{p}", str(precision)) + SUFFIXES[index]
		
func _on_button_pressed(panel_name: String):
	panel_name = panel_name.to_lower()
	
	var path = "res://Sprites/" + panel_name  + ".svg"
	var sprite = load(path)
	selectUI.get_node("Icon/TextureRect").texture = sprite
	var details = selectUI.get_node("Details/MarginContainer/VBoxContainer")
	
	details.get_node("name").text = panel_name.to_upper()
	details.get_node("level").text = "Level 1"
	details.get_node("value").text = "₱ " + format_number_abbreviated(gameManager.objValues[panel_name])
	
	print("Button from panel: ", panel_name)
	if gameManager.current_tool == panel_name:
		gameManager.current_tool = "none"
		
		var slide_distance = selectUI.size.x
		var target_x = selectUI.position.x - slide_distance
		var target_position = Vector2(target_x, selectUI.position.y)
		var duration = 0.3 
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(selectUI, "position", target_position, duration)
	else:
		if gameManager.current_tool == "none":
			var slide_distance = selectUI.size.x
			var target_x = selectUI.position.x + slide_distance
			var target_position = Vector2(target_x, selectUI.position.y)
			var duration = 0.3 
			
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			tween.tween_property(selectUI, "position", target_position, duration)
		else:
			var slide_distance = selectUI.size.x
			var target_x = selectUI.position.x - slide_distance
			var target_position = Vector2(target_x, selectUI.position.y)
			var duration = 0.3 
			
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			tween.tween_property(selectUI, "position", target_position, duration)
			
			await tween.finished
			
			print("going back")
			var target_x2 = selectUI.position.x + slide_distance
			var target_position2 = Vector2(target_x2, selectUI.position.y)
			
			var tween2 = create_tween()
			tween2.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			tween2.tween_property(selectUI, "position", target_position2, duration)
			
		gameManager.current_tool = panel_name.to_lower()
		print("changed to" + panel_name.to_lower())
		
	gameManager._update_ui()
	
