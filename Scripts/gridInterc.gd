extends Camera3D

@onready var map = $"../map1"
@onready var gameManager = get_node("../GameManager")
@onready var ghostBlocks = get_node("../ghostBlocks/logic")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var grid_pos = ghostBlocks.grid_pos
		if gameManager.current_tool == "drain":
			print("Clicked grid:", grid_pos)
			gameManager.place_drain(grid_pos)
