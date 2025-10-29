extends MarginContainer

@onready var gameManager = get_node("../../../../../GameManager")
@onready var UI = get_node("../../../../../UI")

func _ready():
	for button in get_node("HBoxContainer2").get_children():
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(button.name))

func _on_button_pressed(button: String):
	button = button.to_lower()
	match button:
		"building":
			var assets = get_node("../../../../../map/Assets")
			if assets.visible == true:
				assets.visible = false
			else:
				assets.visible = true
		"grid":
			var grid = get_node("../../../../../map/gridPlane")
			if grid.visible == true:
				grid.visible = false
			else:
				grid.visible = true
		"pipes":
			pass
		"fx":
			pass
