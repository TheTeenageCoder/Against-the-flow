extends Control

@onready var label = $Label
var tween: Tween

func _ready():
	modulate.a = 0.0  

func show_message(notif: String, color: Color = Color.WHITE):
	label.text = notif
	modulate = color
	
	position -= Vector2(0, 200)
	modulate.a = 1.0
	
	tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 50, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	
	tween.finished.connect(queue_free)
