extends Node2D

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var video_stream = preload("res://Cutscenes/prolouge.ogv")
@onready var fade_rect = get_node("FadeRect")

# --- Add a reference to your click sound AudioStreamPlayer ---
@onready var click_sound: AudioStreamPlayer = $ClickSound  # make sure you have one in your scene

var save_path := "user://data.json"

enum ScaleMode { COVER, FIT }
var scale_mode := ScaleMode.COVER

var is_playing = false

var act  := -1:
	set(value):
		act = value
		save_game()

func _ready():
	video_player.stream = video_stream
	video_player.play()
	is_playing = true
	video_player.finished.connect(_on_video_finished)
	call_deferred("_fit_video_to_viewport")

	# --- Connect all Button descendants to play sound on click ---
	connect_all_buttons(self)

var dialougeIndex = 0
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_playing == false:
			if dialougeIndex == 0:
				$Dialouge/MarginContainer/VBoxContainer/text/Label.text = "I can’t wait to meet the governor, but, oh…wait! I need to run a simulation first. As they say, preparedness is the key to success and victory!"
				dialougeIndex += 1
			elif dialougeIndex == 1:
				$Dialouge/MarginContainer/VBoxContainer/text/Label.text = "If the model fails here, the real deal fails out there. I will do this right."
				dialougeIndex += 1
			elif dialougeIndex == 2:
				await fade("out")
				get_tree().change_scene_to_file("res://scene.tscn")

func _on_video_finished():
	print("Video finished")
	act += 1
	video_player.visible = false
	is_playing = false

func fade(direction: String, duration: float = 1.0) -> void:
	if direction == "in":
		fade_rect.modulate.a = 1.0
	else:
		fade_rect.modulate.a = 0.0

	var target_alpha: float = 0.0 if direction == "in" else 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	await tween.finished

func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(act)
		file.store_string(json_text)
		file.close()

func _fit_video_to_viewport() -> void:
	var tex = video_player.get_video_texture()
	if not tex:
		await get_tree().process_frame
		tex = video_player.get_video_texture()
		if not tex:
			push_warning("Video texture not available; cannot fit video.")
			return

	var viewport_size_i = get_viewport().size         
	var viewport_size = Vector2(viewport_size_i.x, viewport_size_i.y)
	var video_size = tex.get_size()

	var s = Vector2(viewport_size.x / video_size.x, viewport_size.y / video_size.y)

	if scale_mode == ScaleMode.COVER:
		var chosen = max(s.x, s.y)
		video_player.scale = Vector2(chosen, chosen)
	else:
		var chosen = min(s.x, s.y)
		video_player.scale = Vector2(chosen, chosen)

	video_player.position = viewport_size * 0.5 - (video_size * video_player.scale * 0.5)

# --- Button click sound system ---
func connect_all_buttons(node: Node):
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(_on_button_pressed)
		connect_all_buttons(child)  # recurse through all descendants

func _on_button_pressed():
	if click_sound:
		click_sound.play()
