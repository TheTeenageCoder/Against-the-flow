extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("meta_clicked", Callable(self,"_on_meta_clicked")) # Replace with function body.

func _on_meta_clicked(meta):
	OS.shell_open(meta) # Replace with function body.
