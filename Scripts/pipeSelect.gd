extends VBoxContainer

@onready var gameManager = get_node("../../../../GameManager")
@onready var UI = get_node("../../..")

@onready var pipeSelection = get_node("..")

func _ready():
	for panel in get_children():
		if panel.has_node("TextureButton"):
			var button = panel.get_node("TextureButton")
			button.connect("pressed", Callable(self, "_on_button_pressed").bind(panel.name))
		
func _on_button_pressed(panel_name: String):
	panel_name = panel_name.to_lower()
	if gameManager.current_tool == panel_name:
		gameManager.current_tool = "pipe"
	else:
		gameManager.current_tool = panel_name.to_lower()
		
	gameManager._update_ui()
	
