extends MarginContainer

@onready var gameManager = get_node("../../../../../GameManager")
@onready var UI = get_node("../../../../../UI")
@onready var map 


func _ready():
	while not gameManager.is_loaded:
		await get_tree().process_frame
		
	for child in  $"../../../../..".get_children():
		if child is Node3D:
			map = child
			
	for button in get_node("HBoxContainer2").get_children():
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(button.name))

func _on_button_pressed(button: String):
	button = button.to_lower()
	match button:
		"building":
			var assets = map.get_node("Assets")
			if assets.visible == true:
				assets.visible = false
			else:
				assets.visible = true
		"grid":
			var grid = map.get_node("gridPlane")
			if grid.visible == true:
				grid.visible = false
			else:
				grid.visible = true
		"fx":
			pass
