extends Control

@onready var click_sound: AudioStreamPlayer = $ClickSound  # or wherever your sound node is

func _ready():
	connect_all_buttons(self)

# Recursive function to connect all button descendants
func connect_all_buttons(node: Node):
	for child in node.get_children():
		if child is Button or child is TextureButton:
			child.pressed.connect(_on_button_pressed)  
		connect_all_buttons(child)  # recurse through children

func _on_button_pressed():
	if click_sound:
		click_sound.play()
