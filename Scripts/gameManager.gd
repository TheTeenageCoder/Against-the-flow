extends Node

@onready var gridInterc = get_node("gridInteraction")
@onready var notif = get_node("../UI/notifManager")
@onready var map = get_node("../map")
@onready var fade_rect = get_node("../UI/FadeRect")

var save_path := "user://data.json"

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
		
var dialougeIndex = 0
var needPipeDialouge = false
var needLayerDialouge = false
var needDrainDialouge = false
var needDemolishDialouge = false
var needConnectionDialouge = false
		
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

signal phase_changed(phase)

var waiting := true

func _ready():
	_update_ui()
	while act == null:
		load_game()
		await get_tree().process_frame
	await fade("in")
		
	print("game loaded - Act: " + str(act))
	
	flood_level = 0.0
	flood_rise_speed = 1.0
	drain_effectiveness = 0.0
	
	phase = "building"
	
	if act == -1:
		get_tree().change_scene_to_file("res://prolouge.tscn")
	
	if act == 0:
		print("Tutorial started — November: building")
		flood_treshold = 1.5
		current_month = 11
		
		#while current_month < 12:
			##await get_tree().create_timer(month_duration).timeout
			##current_month += 1
			##if current_month == 12:
				##phase = "storm"
				##emit_signal("phase_changed", phase)
		#hile phase == "building":
			#await get_tree().process_frame
		#while phase == "storm":
			#await get_tree().process_frame
			#
		#print("storm done")
		#emit_signal("phase_changed", phase)
		#print(flood_level)
		#act += 1
		
	if act == 1:
		print("Act I started — January: building")
		current_month = 1
		flood_treshold = 1.5
		while current_month < 12:
			await get_tree().create_timer(month_duration).timeout
			current_month += 1
			if current_month == 12:
				phase = "storm"
				emit_signal("phase_changed", phase)
				
				flood_level = 0.0
				flood_rise_speed = 1.0
				drain_effectiveness = 0.0
				
		await get_tree().create_timer(month_duration).timeout
		print("storm done")
		phase = "building"
		emit_signal("phase_changed", phase)
		print(flood_level)
		act += 1
		load_game()
		#emit_signal("phase_changed", phase)

var elapsed_time := 0.0

var layerOpen = false
var layerOpen2 = false
func _process(delta):
	map.get_node("Placed").check_connection()
	if is_game_over:
		return
		
	#print(act)
	if act == 0:	
		if dialougeIndex == 0:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "Okay, so… First, things first, I need to place drains around the city."
			needDrainDialouge = true
		elif dialougeIndex == 1:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "I can’t place drains on top of those buildings."
		elif dialougeIndex == 2:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "That looks good, now I need to go underground to place pipes."
			$"../UI/Control/arrow".global_position = Vector2(1835, 177)
			$"../UI/Control/arrow".rotation = -90
			needLayerDialouge = true
		elif dialougeIndex == 3:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "These pipes need to be connected to that outer pipe to drain the water."
			$"../UI/Control/arrow".global_position = Vector2(1800, 455)
			$"../UI/Control/arrow".rotation = 0
			needPipeDialouge = true
		elif dialougeIndex == 4:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "I need to make sure these pipes are all connected to let the water fully drain."
			needConnectionDialouge = true
		elif dialougeIndex == 5:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "Now that’s done… I’ll simulate rain to test this system."
			if not layerOpen2:
				$"../UI/Control/topRight/Layer"._toggle_layer_animated()
				layerOpen2 = true
			phase = "storm"
			flood_treshold = 0.25
			needConnectionDialouge = true
		elif dialougeIndex == 6:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "Oh..! This needs more drains. I’ll set up more: I need to destroy these pipes for now and I’ll connect the new drains."
			$"../UI/Control/arrow".global_position = Vector2(1800, 515)
			needDemolishDialouge = true
		elif dialougeIndex == 7:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "Destroying these pipes will give me a portion of the money back."
			needConnectionDialouge = true
		elif dialougeIndex == 8:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "Just to make sure, I’ll upgrade these pipes to drain more water."
			$"../UI/Control/arrow".global_position = Vector2(1800, 575)
		elif dialougeIndex == 9:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "Okay! Now, let’s test it again."
			$"../UI/Control/arrow".visible = false
			if not layerOpen:
				$"../UI/Control/topRight/Layer"._toggle_layer_animated()
				layerOpen = true
			flood_treshold = 0.25
			month_duration = 10
			phase = "storm"
		elif dialougeIndex == 10:
			$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/text/Label".text = "Alright! Now, I’m more than ready to face the challenge that the Governor gave me!"
			is_game_over = true
			await get_tree().create_timer(5).timeout
			act += 1
			await fade("out")
			get_tree().reload_current_scene()
		
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
				dialougeIndex += 1
			phase = "building"
			flood_level = 0.0
			flood_node.mesh.size.y = prevSize
			flood_node.position.y = prevPos
			flood_node.visible = false
			$"../UI/GPUParticles2D".visible = false
		
func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(act)
		file.store_string(json_text)
		file.close()
		#print("✅ Game saved to:", save_path)
	#else:
		#print("❌ Failed to open file for saving")

func load_game():
	if not FileAccess.file_exists(save_path):
		print("⚠ No save file found.")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	var json_text = file.get_as_text()
	#print("File contents:", json_text)
	file.close()

	var result = JSON.parse_string(json_text)
	if result != null:
		act = result
		#print("✅ Game loaded:", act)
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

#func _process_storm(delta):
	#for i in range(total_drains):
		#if randf() < random_break_chance * delta:
			#_break_random_drain()
#
	#var reduction = working_drains * 0.05
	#flood_level += (flood_rise_speed - reduction) * delta
#
	#if flood_level < 0:
		#flood_level = 0
	#if flood_level > 10:
		#_trigger_flood_gameover()
#
	#emit_signal("flood_updated", flood_level)
#
#func _break_random_drain():
	#if total_drains <= 0:
		#return
	#var broken_id = "Drain" + str(randi_range(1, total_drains))
	#if broken_id in broken_drains:
		#return
	#broken_drains.append(broken_id)
	#working_drains = max(0, working_drains - 1)
	#print("🚨", broken_id, "broken!")
	#emit_signal("drain_broken", broken_id)
#
#func repair_drain(id: String):
	#if id in broken_drains:
		#broken_drains.erase(id)
		#working_drains += 1
		#print("🔧", id, "repaired!")
#
#func _trigger_flood_gameover():
	#print("💦 City flooded! Game Over!")
	#is_game_over = true
#
#func _end_game():
	#is_game_over = true
	#print("✅ Tutorial complete!")

func end_game():
	get_tree().reload_current_scene()
	
	# We don't call _ready() here anymore.
func _update_ui():
	if has_node("../UI"):
		var ui = get_node("../UI")
		ui.update_ui(money, current_month, current_tool, phase)
