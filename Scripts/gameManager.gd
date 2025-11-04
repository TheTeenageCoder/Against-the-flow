extends Node

@onready var gridInterc = get_node("gridInteraction")
@onready var notif = get_node("../UI/notifManager")
@onready var map = get_node("../map")
@onready var fade_rect = get_node("../UI/FadeRect")
@onready var dialog_label = $"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label"
@onready var typing_audio = $"../UI/Control/typing_sound"
@onready var light_rain = $"../UI/Control/rain"
@onready var medium_rain = $"../UI/Control/rain2"
@onready var heavy_Rain = $"../UI/Control/rain3"

var save_path := "user://data.json"

# === Typing / Dialogue ===
var typing_speed := 0.03 #
var typing_in_progress := false
var typing_cancelled := false
var last_full_text := ""

# === Player Data ===
var money := 50000000:
	set(value):
		var polarity = "-" if money > value else "+"
		var text = polarity + "₱" + str(abs(money-value))
		var color = Color(1.0, 0.0, 0.0, 1.0) if money > value else Color(0.0, 1.0, 0.0, 1.0)
		notif.notify(text, color)
		money = value
		_update_ui()
var current_tool := "none":
	set(value):
		current_tool = value
		gridInterc.update_obj(value)
		_update_ui()
var in_dialouge := false
		
var act: int:
	set(value):
		act = value
		save_game()
		
var dialougeIndex := 0.0:
	set(value):
		if dialougeIndex != value:
			dialougeIndex = value
			_on_dialouge_index_changed(value)

var needPipeDialouge = false
var needLayerDialouge = false
var needDrainDialouge = false
var needDemolishDialouge = false
var needConnectionDialouge = false
var needInvalidDialouge = false
		
# === Pipe/Drain Data ===
var drains := {}
var pipes := {}
var upgradedDrains := []
var pipesUpgraded := false
var pipesMultiplier := 1.0

# === Time ===
var current_month = 11:
	set(value):
		current_month = value
		_update_ui()
		
var max_months := 2
var month_duration := 20.0

# === Game Phases ===
var phase := "building":
	set(value):
		phase = value
		if value == "building":
			get_node("../map/flood").visible = false
		if value == "storm":
			get_node("../map/flood").visible = true
		_update_ui()
var is_game_over := false

# === Flood System ===
var flood_level := 0.0
var flood_rise_speed := 1.0
var drain_effectiveness := 0.0
var flood_treshold := 0.0

var objValues := {
	"drain": 300000,
	"pipe": 500000,
	"demolish": 0,
	"upgrade": 0,
	"fix": 0
}

# === Events ===
var random_break_chance := 0.01


var waiting := true

func _ready():
	_update_ui()
	await load_game()
	await fade("in")
		
	print("game loaded - Act: " + str(act))
	
	flood_level = 0.0
	flood_rise_speed = 1.0
	drain_effectiveness = 0.0
	
	phase = "building"
	
	if act == -1:
		get_tree().change_scene_to_file("res://prolouge.tscn")
	
	if act == 0:
		fade_rect.mouse_filter = 1
		print("Tutorial started — November: building")
		current_month = 11
		_on_dialouge_index_changed(0)
	
	if act == 1:
		print("Act I started — January: building")
		fade_rect.mouse_filter = 2

var elapsed_time := 0.0

var layerOpen = false
var layerOpen2 = false

var skippable = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and skippable == true:
		print("skip")
		
		var tween = create_tween()
		tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ZERO, 0.25 * 0.8)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished
		$"../UI/Control/Dialouge".visible = false
		fade_rect.mouse_filter = 2
		skippable = false

func type_text(label: Label, full_text: String) -> void:
	# Starts typing the given text into the label, playing typing_audio while typing.
	# If another typing is already active, request it to cancel and wait a frame.
	if typing_in_progress:
		typing_cancelled = true
		# let the previous coroutine wind down
		await get_tree().process_frame

	typing_cancelled = false
	typing_in_progress = true
	label.text = ""
	last_full_text = full_text
	if typing_audio:
		typing_audio.play()

	for i in range(full_text.length()):
		if typing_cancelled:
			break
		label.text += full_text[i]
		await get_tree().create_timer(typing_speed).timeout

	# stop typing_audio and finalize text
	if typing_audio:
		typing_audio.stop()
	if typing_cancelled:
		label.text = full_text
	typing_in_progress = false

func start_type_text(label: Label, text: String, wait_for_finish: bool = true) -> void:
	if wait_for_finish:
		await type_text(label, text)
	else:
		# start coroutine, don't block
		type_text(label, text)

# ---------- Main process ----------
func _process(delta):
	map.get_node("Placed").check_connection()
	if is_game_over:
		return
	
	if phase == "storm":
		$"../UI/GPUParticles2D".visible = true
		$"../map/flood".visible = true
		
		var reduction = 0
		for key in drains.keys():
			if drains[key][0] == true:
				reduction += drains[key][1]
		reduction *= pipesMultiplier
			
		flood_level += ((flood_rise_speed - reduction) * delta)/12
		flood_level = max(flood_level, 0.0)
		
		var flood_node = map.get_node("flood")
		var prevSize = flood_node.mesh.size.y
		var prevPos = flood_node.position.y
		flood_node.mesh.size.y = flood_level
		flood_node.position.y = 0.35 + (flood_level / 2.0)

		elapsed_time += 0.1
		if elapsed_time > 300:
			print("Storm has passed")
			phase = "building"
			if act == 0:
				dialougeIndex += 1
			$"../UI/GPUParticles2D".visible = false
			flood_level = 0.0
			flood_node.mesh.size.y = prevSize
			flood_node.position.y = prevPos
			flood_node.visible = false
		if map.get_node("flood").mesh.size.y  > flood_treshold:
			if act == 0:
				dialougeIndex = 6
			phase = "building"
			flood_level = 0.0
			flood_node.mesh.size.y = prevSize
			flood_node.position.y = prevPos
			flood_node.visible = false
			$"../UI/GPUParticles2D".visible = false

func _on_dialouge_index_changed(index: float) -> void:
	if act != 0:
		return  # Only handle for act 0
	if current_tool != "none":
		current_tool = "none"
		var slide_distance = $"../UI/Control/leftSelect".size.x
		var target_x = $"../UI/Control/leftSelect".position.x - slide_distance
		var target_position = Vector2(target_x, $"../UI/Control/leftSelect".position.y)
		var duration = 0.3 

		var tweenSelect = create_tween()
		tweenSelect.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
		tweenSelect.tween_property($"../UI/Control/leftSelect", "position", target_position, duration)
	fade_rect.mouse_filter = 1
	$"../UI/Control/Dialouge".visible = true
	print("DIalouge start")
	print(dialougeIndex)
	var tween = create_tween()
	tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE, 0.25 * 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	match index:
		0.0:			
			await start_type_text(dialog_label, "Okay, so… First, things first, I need to place drains around the city.")
			needInvalidDialouge = true
			skippable = true
		1.0:
			await start_type_text(dialog_label, "I can’t place drains on top of those buildings.")
			needDrainDialouge = true
			skippable = true
		2.0:
			await start_type_text(dialog_label, "That looks good, now I need to go underground to place pipes.")
			$"../UI/Control/arrow".global_position = Vector2(1835, 177)
			$"../UI/Control/arrow".rotation = deg_to_rad(-90)
			skippable = true
			needLayerDialouge = true
		3.0:
			await start_type_text(dialog_label, "These pipes need to be connected to that outer pipe to drain the water.")
			$"../UI/Control/arrow".global_position = Vector2(1800, 455)
			$"../UI/Control/arrow".rotation = 0
			skippable = true
			needPipeDialouge = true
		4.0:
			await start_type_text(dialog_label, "I need to make sure these pipes are all connected to let the water fully drain.")
			needConnectionDialouge = true
			skippable = true
		5.0:
			await start_type_text(dialog_label, "Now that’s done… I’ll simulate rain to test this system.")
			skippable = true
			if not layerOpen2:
				$"../UI/Control/topRight/Layer"._toggle_layer_animated()
				layerOpen2 = true
			phase = "storm"
			flood_treshold = 0.25
		6.0:
			await start_type_text(dialog_label, "Oh..! This needs more drains. I’ll set up more: I need to destroy these pipes for now and I’ll connect the new drains.")
			$"../UI/Control/arrow".global_position = Vector2(1800, 515)
			skippable = true
			needDemolishDialouge = true
		7.0:
			await start_type_text(dialog_label, "Destroying these pipes will give me a portion of the money back.")
			skippable = true
			needConnectionDialouge = true
		8.0:
			await start_type_text(dialog_label, "Just to make sure, I’ll upgrade these pipes to drain more water.")
			skippable = true
			$"../UI/Control/arrow".global_position = Vector2(1800, 575)
		9.0:
			await start_type_text(dialog_label, "Okay! Now, let’s test it again.")
			$"../UI/Control/arrow".visible = false
			if not layerOpen:
				$"../UI/Control/topRight/Layer"._toggle_layer_animated()
				layerOpen = true
			skippable = true
			flood_treshold = 0.25
			month_duration = 10
			phase = "storm"
		10.0:
			await start_type_text(dialog_label, "Alright! Now, I’m more than ready to face the challenge that the Governor gave me!", true)
			is_game_over = true
			act += 1
			await fade("out")
			get_tree().reload_current_scene()
		_: 
			$"../UI/Control/Dialouge".visible = false
			
func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(act)
		file.store_string(json_text)
		file.close()

func load_game():
	if not FileAccess.file_exists(save_path):
		print("⚠ No save file found.")
		return

	
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json_text = file.get_as_text()
	print("Act: " + json_text)
	file.close()

	var result = JSON.parse_string(json_text)
	if result != null:
		act = result
	else:
		print("❌ Failed to parse JSON")

func fade(direction: String, duration: float = 2.0) -> void:
	if direction == "in":
		fade_rect.modulate.a = 1.0
	else:
		fade_rect.modulate.a = 0.0
	
	var target_alpha: float = 0.0 if direction == "in" else 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	await tween.finished

func end_game():
	get_tree().reload_current_scene()

func _update_ui():
	if has_node("../UI"):
		var ui = get_node("../UI")
		ui.update_ui(money, current_month, current_tool, phase)
