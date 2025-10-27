extends Camera3D

@onready var map = $"../map1"

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var space_state = get_world_3d().direct_space_state

		# Create ray parameters properly
		var from = project_ray_origin(event.position)
		var to = from + project_ray_normal(event.position) * 1000
		var query = PhysicsRayQueryParameters3D.create(from, to)

		# Perform raycast
		var result = space_state.intersect_ray(query)

		if result:
			var pos = result.position
			var grid_pos = map.world_to_grid(pos)
			print("Clicked grid:", grid_pos)
