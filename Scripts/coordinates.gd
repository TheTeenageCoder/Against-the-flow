extends Node3D

@export var tile_size := 1.0
var occupied := {}

func _ready():
	register_existing_blocks()

func register_existing_blocks():
	
	for cube in $Layer0.get_children():
		var grid_pos = world_to_grid(cube.position)
		occupied[grid_pos] = true

func world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(round(world_pos.x / tile_size), round(world_pos.y / tile_size), round(world_pos.z / tile_size))

func grid_to_world(grid_pos: Vector3i) -> Vector3:
	return Vector3(grid_pos.x * tile_size, grid_pos.y * tile_size, grid_pos.z * tile_size)


	
