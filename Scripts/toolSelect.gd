extends VBoxContainer

@onready var gameManager = get_node("../../../../GameManager")
@onready var UI = get_node("../../../../UI")

func _ready():
	for panel in get_children():
		if panel.has_node("TextureButton"):
			var button = panel.get_node("TextureButton")
			button.connect("pressed", Callable(self, "_on_button_pressed").bind(panel.name))

func _on_button_pressed(panel_name: String):
	panel_name = panel_name.to_lower()
	print("Button from panel: ", panel_name)
	if gameManager.current_tool == panel_name:
		gameManager.current_tool = "none"
	else:
		gameManager.current_tool = panel_name.to_lower()
		print("changed to" + panel_name.to_lower())
	gameManager._update_ui()
	
