extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _on_pressed() -> void:
	get_node("../../Options2").visible = false# Replace with function body.
	get_node("../../Credits2").visible = false

@warning_ignore("unused_parameter")
func _input(event):
	if Input.is_action_just_pressed("esc"):
		get_node("../../Options2").visible = false
		get_node("../../Credits2").visible = false
