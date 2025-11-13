extends Node2D

@export var tween_intensity: float = 1.1
@export var tween_duration: float = 0.2

@onready var start: Button = $Start
@onready var options: Button = $Options
@onready var credits: Button = $Credits
@onready var exit: Button = $"Exit Game"
@onready var leaderboard: Button = $Leaderboard
@onready var bg: TextureRect = $Background
@onready var fx: GPUParticles2D = $GPUParticles2D
@onready var click_sound: AudioStreamPlayer = $ClickSound  
@onready var fade_rect: ColorRect = $FadeRect

func _ready() -> void:
	_setup_button(start, Callable(self, "_on_start_pressed"))
	_setup_button(options, Callable(self, "_on_options_pressed"))
	_setup_button(credits, Callable(self, "_on_credits_pressed"))
	_setup_button(exit, Callable(self, "_on_exit_pressed"))
	_setup_button(leaderboard, Callable(self, "_on_leaderboard_pressed"))

# --- Setup each button with hover, click, and sound connections ---
func _setup_button(button: Button, callback: Callable) -> void:
	if not button:
		return
	button.pivot_offset = button.size / 2
	button.connect("mouse_entered", Callable(self, "_on_button_hovered").bind(button))
	button.connect("mouse_exited", Callable(self, "_on_button_unhovered").bind(button))
	button.connect("pressed", callback)
	button.connect("pressed", Callable(self, "_on_any_button_pressed"))  # <-- Add sound trigger

# --- Tween utility ---
func start_tween(object: Object, property: String, final_val: Variant, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(object, property, final_val, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# --- Hover behavior ---
func _on_button_hovered(button: Button) -> void:
	button.pivot_offset = button.size / 2
	start_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	start_tween(button, "modulate", Color.BLACK, tween_duration)

	if button == exit:
		fx.visible = true
		start_tween(bg, "modulate", Color.WEB_GRAY, tween_duration + 0.5)

func _on_button_unhovered(button: Button) -> void:
	button.pivot_offset = button.size / 2
	start_tween(button, "scale", Vector2.ONE, tween_duration)
	start_tween(button, "modulate", Color.WHITE, tween_duration)

	if button == exit:
		fx.visible = false
		start_tween(bg, "modulate", Color.WHITE, tween_duration + 0.5)

# --- Universal click sound ---
func _on_any_button_pressed() -> void:
	if click_sound:
		click_sound.play()

# --- Button pressed handlers ---
func _on_start_pressed() -> void:
	await fade("out")
	get_tree().change_scene_to_file("res://scene.tscn")

func _on_options_pressed() -> void:
	$Options2.visible = true

func _on_credits_pressed() -> void:
	$Credits2.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_leaderboard_pressed() -> void:
	pass

func fade(direction: String, duration: float = 1.0) -> void:
	if direction == "in":
		fade_rect.modulate.a = 1.0
	else:
		fade_rect.modulate.a = 0.0

	var target_alpha: float = 0.0 if direction == "in" else 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	await tween.finished
