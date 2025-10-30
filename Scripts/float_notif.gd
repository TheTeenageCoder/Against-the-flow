extends Node

@export var notification_scene: PackedScene

func notify(text: String, color: Color = Color.WHITE):
	notification_scene = preload("res://Scenes/notification.tscn")
	
	var notif = notification_scene.instantiate()
	add_child(notif)
	notif.position = get_viewport().get_visible_rect().size / 2  
	notif.show_message(text, color)
