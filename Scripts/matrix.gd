extends Node3D

var tile_coords = get_parent().get_occupied_tiles()
var tile_coords_2d = []
func _ready() -> void:
	for v in tile_coords:
		tile_coords_2d.append(Vector2(v.x, v.z))
	
	var n = tile_coords_2d.size()
	var matrix = []
	
	for i in n:
		matrix.append([])
		for j in n:
			matrix[i].append(0)
		
	

func _process(_delta: float) -> void:
	pass

	# Initialize n×n matrix with 0s
