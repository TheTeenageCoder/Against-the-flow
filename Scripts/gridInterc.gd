extends Node3D

@export var camera: Camera3D
@export var ghost_scene: PackedScene

@onready var map = $"../../map"
@onready var gameManager = get_node("..")

var grid_pos

func _ready():
	if camera == null:
		camera = get_viewport().get_camera_3d()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#var grid_pos = ghostBlocks.grid_pos
		if gameManager.current_tool == "drain":
			print("Clicked grid:", grid_pos)
			gameManager.place_drain(grid_pos)
