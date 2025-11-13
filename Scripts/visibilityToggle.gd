extends MarginContainer

@onready var gameManager = get_node("../../../../../GameManager")
@onready var UI = get_node("../../../../../UI")
@onready var map 

var save_path := "user://data.json"

var act

func load_game():
	if not FileAccess.file_exists(save_path):
		print("⚠ No save file found.")
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json_text)
	if result != null:
		act = result
	else:
		print("❌ Failed to parse JSON")

func _ready():
	load_game()
	
	if act != -1:
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
