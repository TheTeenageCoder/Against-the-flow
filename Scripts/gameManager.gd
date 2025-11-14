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
@onready var warningIcon = preload("res://Scenes/warningIcon.tscn")

var is_loaded = false
var save_path := "user://data.json"

# === Typing / Dialogue ===
var typing_speed := 0.03
var typing_in_progress := false
var typing_cancelled := false
var last_full_text := ""

# === Player Data ===
var money := 50000000.00:
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
var needUpgradeDialouge = false
		
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
var month_duration := 0.0
var storm_duration := 0.0

# === Game Phases ===
signal phase_changed(value)

var phase := "building":
	set(value):
		if phase != value:
			phase = value
			if value == "building":
				$"../UI/GPUParticles2D".visible = false
				if $"../UI/Control/rain".is_playing():
					$"../UI/Control/rain".stop()
			if value == "storm":
				map.get_node("flood").visible = true
				$"../UI/GPUParticles2D".visible = true
				if not $"../UI/Control/rain".is_playing():
					$"../UI/Control/rain".play()
			_update_ui()
var is_game_over := false

# === Flood System ===
var flood_level := 0.0
var flood_rise_speed := 1.0
var drain_effectiveness := 0.0
var flood_treshold := 0.25
var can_break := false

var objValues := {
	"drain": 300000,
	"pipe": 500000,
	"demolish": 0,
	"upgrade": 0,
	"fix": 0
}

var waiting := true

func _ready():
	set_process(false)
	_update_ui()
	await get_tree().process_frame
	await load_game()
	print("Game loaded - Act: " + str(act))
	
	flood_level = 0.0
	flood_rise_speed = 1.0
	drain_effectiveness = 0.0
	
	phase = "building"
	
	if act == -1:
		get_tree().change_scene_to_file("res://prolouge.tscn")
	
	if act == 0:
		fade_rect.mouse_filter = 1
		print("Tutorial started — November: building")
		map.queue_free()
		var newMap = load("res://Scenes/maps/map0.tscn").instantiate()
		$"..".add_child(newMap)
		current_month = 11
		$"../UI/Control/topLeft/VBoxContainer/HBoxContainer/Place/Label".text = "SIMULATION"
		$"../UI/Control/arrow".visible = true
		_on_dialouge_index_changed()
	
	if act == 1:
		print("Act I started — January: building")
		map.queue_free()
		var newMap = load("res://Scenes/maps/map1.tscn").instantiate()
		$"..".add_child(newMap)
		$"../Camera3D".position.x += 15
		current_month = 1
		$"../UI/Control/topLeft/VBoxContainer/HBoxContainer/Place/Label".text = "SINCERRA CITY"
		month_duration = 5
		storm_duration = 20
		flood_treshold = 1
		_on_dialouge_index_changed()
	
	if act == 2:
		print("Act II started — January: building")
		map.queue_free()
		var newMap = load("res://Scenes/maps/map2.tscn").instantiate()
		$"..".add_child(newMap)
		$"../Camera3D".position.x += 15
		current_month = 1
		$"../UI/Control/topLeft/VBoxContainer/HBoxContainer/Place/Label".text = "TIGASULO CITY"
		month_duration = 10
		storm_duration = 30
		flood_treshold = 0.75
		_on_dialouge_index_changed()
		
	if act == 3:
		print("Act III started — January: building")
		map.queue_free()
		var newMap = load("res://Scenes/maps/map3.tscn").instantiate()
		$"..".add_child(newMap)
		$"../Camera3D".position.x += 15
		current_month = 1
		$"../UI/Control/topLeft/VBoxContainer/HBoxContainer/Place/Label".text = "MAGARA CITY"
		month_duration = 30
		storm_duration = 60
		flood_treshold = 0.75
		_on_dialouge_index_changed()
	
	if act != -1:
		for child in $"..".get_children():
			if child is Node3D:
				map = child
		
		await get_tree().create_timer(0.5).timeout
		is_loaded = true
		set_process(true)
		$"../UI/Black".visible = false
		await fade("in")

var elapsed_time := 0.0

var layerOpen = false
var layerOpen2 = false

var skippable = false
var runThrough = false

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if skippable:
			var tween = create_tween()
			tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.2)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ZERO, 0.25 * 0.8)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			await tween.finished
			$"../UI/Control/Dialouge".visible = false
			fade_rect.mouse_filter = 2
			skippable = false
		elif runThrough:
			dialougeIndex += 1
		elif not runThrough or not skippable:
			typing_cancelled = true

func type_text(label: Label, full_text: String) -> void:
	if typing_in_progress:
		typing_cancelled = true
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
		if flood_rise_speed > 2.0:
			var under := map.get_node("Placed/under").get_children()
			var valid_children := under.filter(func(c):
				return c.name != "output"
			)
			if valid_children.size() > 0 and randf() < 0.001:
				destroy("pipe", valid_children.pick_random())
	
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
	
		elapsed_time += 1
		if elapsed_time > storm_duration*Engine.get_frames_per_second():
			print("Storm has passed")
			phase = "building"
			if act == 0:
				dialougeIndex = 9
			flood_level = 0.0
	
			storm_pass(flood_node, prevSize, prevPos)
				
			elapsed_time = 0
			emit_signal("phase_changed", phase)
		if map.get_node("flood").mesh.size.y  > flood_treshold:
			if act == 0:
				dialougeIndex = 5
				phase = "building"
				flood_level = 0.0
				storm_pass(flood_node, prevSize, prevPos)
			else:
				await fade("out")
				get_tree().reload_current_scene()
					
func _on_dialouge_index_changed(index: float = 0) -> void:
	if act == 0:
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
		skippable = false
		runThrough = false
		var tween = create_tween()
		tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE, 0.25 * 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		match index:
			0.0:
				await start_type_text(dialog_label, "Okay, so… First, things first, I need to place drains around the city.")
				needDrainDialouge = true
				skippable = true
			1.0:
				await start_type_text(dialog_label, "That looks good, now I need to go underground to place pipes.")
				$"../UI/Control/arrow".global_position = Vector2(1835, 177)
				$"../UI/Control/arrow".rotation = deg_to_rad(-90)
				skippable = true
				needLayerDialouge = true
			2.0:
				await start_type_text(dialog_label, "These pipes need to be connected to that outer pipe to drain the water.")
				$"../UI/Control/arrow".global_position = Vector2(1800, 455)
				$"../UI/Control/arrow".rotation = 0
				skippable = true
				needPipeDialouge = true
			3.0:
				await start_type_text(dialog_label, "I need to make sure these pipes are all connected to let the water fully drain.")
				needConnectionDialouge = true
				skippable = true
			4.0:
				await start_type_text(dialog_label, "Now that’s done… I’ll simulate rain to test this system.")
				skippable = true
				if not layerOpen2:
					$"../UI/Control/topRight/Layer"._toggle_layer_animated()
					layerOpen2 = true
				storm_duration = 10
				phase = "storm"
			5.0:
				await start_type_text(dialog_label, "Oh..! This needs more drains. I’ll set up more: I need to destroy these pipes for now and I’ll connect the new drains.")
				$"../UI/Control/arrow".global_position = Vector2(1800, 515)
				skippable = true
				needDemolishDialouge = true
			6.0:
				await start_type_text(dialog_label, "Destroying these pipes will give me a portion of the money back.")
				skippable = true
				needConnectionDialouge = true
			7.0:
				await start_type_text(dialog_label, "Just to make sure, I’ll upgrade these pipes to drain more water.")
				needUpgradeDialouge = true
				skippable = true
				$"../UI/Control/arrow".global_position = Vector2(1800, 575)
			8.0:
				await start_type_text(dialog_label, "Okay! Now, let’s test it again.")
				$"../UI/Control/arrow".visible = false
				if not layerOpen:
					$"../UI/Control/topRight/Layer"._toggle_layer_animated()
					layerOpen = true
				skippable = true
				storm_duration = 10
				phase = "storm"
			9.0:
				await start_type_text(dialog_label, "Alright! Now, I’m more than ready to face the challenge that the Governor gave me!", true)
				runThrough = true
			10.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/PEDRO.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "PAPA P"
				await start_type_text(dialog_label, "Greetings, Engineer Dimayuga! Welcome to Verdad Sombra. Beautiful place, terrible drainage. As you know, we have been dealing with regular flooding issues across the province. That’s why we called the best engineer for the job. ")
			11.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Governor, you flatter me. Thank you for this opportunity. I’ve reviewed and analyzed the situation of your cities. The issues are prevalent, but they are not impossible to solve. ")
			12.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/PEDRO.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "PAPA P"
				await start_type_text(dialog_label, "Great! So, let’s talk about the contract. All in all, I want your services for three years. Three cities, Sincerra, Tigasulo, and Magara all need to have their flood control system fixed. You will have a year to improve each city. You’ll start next year in January in Sincerra City. ")
			13.0:
				await start_type_text(dialog_label, "Nothing you can’t handle, right? ")
			14.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "I am ready to begin the development in Sincerra City. With the proper system, we can reduce flooding significantly. I will create something that lasts. ")
			15.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/PEDRO.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "PAPA P"
				await start_type_text(dialog_label, "Lasting solutions… that’s what the community needs. Of course, the more efficient you make it, the more everyone benefits.")
			16.0:
				await start_type_text(dialog_label, "Your solutions could mean children going to school without fear of flooding, business owners earning without disruption, and families waking up to brighter, safer days—that’s what we want, progress that they can feel. Because at the end of the day, everything we do is for the people. ")
			17.0:
				await get_tree().create_timer(2).timeout
				is_game_over = true
				act += 1
				await fade("out")
				get_tree().reload_current_scene()
				
		if dialougeIndex > 9.0:
			runThrough = true
	elif act == 1:
		fade_rect.mouse_filter = 2
		for ui in $"../UI/Control".get_children():
			if not ui is AudioStreamPlayer and ui.name != "Dialouge":
				ui.visible = false
		$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
		$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
		$"../UI/Control/Dialouge".visible = true
		var tween = create_tween()
		tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE, 0.25 * 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		
		runThrough = false
		match index:
			0.0:
				await start_type_text(dialog_label, "[She graduated as an attorney and has a strict attitude towards her work. Coming from a family of politicians, she takes her job very seriously, always being responsible and diligent.]")
			1.0:
				await start_type_text(dialog_label, "Sighs. So… you’re the chief engineer from the company they sent. ")
			2.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Yes, that’s me. Alona Dimayuga at your service.")
			3.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
				await start_type_text(dialog_label, "I’ll be honest with you, Sincerra City is in bad shape. Flooding has impeded the day to day lives of the people. ")
			4.0:
				await start_type_text(dialog_label, "In fact, it’s not an inconvenience anymore. Schools close for weeks, businesses are drowning in debt, and the people have started to lose hope. ")
			5.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Yes, I am well aware of the situation. I’ve read the reports and I won’t let you down. ")
			6.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
				await start_type_text(dialog_label, "I don’t need promises, I need results. The city needs working drainage lines and redirected flow patterns. ")
			7.0:
				await start_type_text(dialog_label, "So, if you’re as good as they say, then… please. Help my city. Help the people believe again. ")
			8.0:
				await start_type_text(dialog_label, "The city is tired and frankly… so am I. ")
			9.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "I won’t waste the opportunity. You have my word.")
			10.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
				await start_type_text(dialog_label, "I don’t need you to impress me. I just need the water to stop rising.")
			11.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Then, let’s get started. Not tomorrow, not next week, now. ")
			12.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
				await start_type_text(dialog_label, "Very well.")
			13.0:
				var tween2 = create_tween()
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ZERO, 0.25 * 0.4)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
				for ui in $"../UI/Control".get_children():
					if not ui is AudioStreamPlayer and ui.name != "Dialouge":
						ui.visible = true
				$"../UI/Control/Dialouge".visible = false
				var storms = {
					"7": "light",
					"12": "medium"
				}
				start_game(storms)
			14.0:
				if current_tool != "none":
					current_tool = "none"
					var slide_distance = $"../UI/Control/leftSelect".size.x
					var target_x = $"../UI/Control/leftSelect".position.x - slide_distance
					var target_position = Vector2(target_x, $"../UI/Control/leftSelect".position.y)
					var duration = 0.3

					var tweenSelect = create_tween()
					tweenSelect.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
						
					tweenSelect.tween_property($"../UI/Control/leftSelect", "position", target_position, duration)
					
				var tween2 = create_tween()
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE, 0.25 * 0.4)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
					
				await start_type_text(dialog_label, "Hard to believe, isn’t it? Same month, same weather… but no water rushing along the streets. No closed establishments, it’s like a whole new city!")
			15.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "The system held up as expected. Let’s just hope that it will keep doing so for years. Though, I assure you, it will. ")
			16.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
				await start_type_text(dialog_label, "I thought “hope” was a word people just threw around. In our city, hope is something that you created. Hope is something you materialized into working drainage systems.")
			17.0:
				await start_type_text(dialog_label, "At first, I admit, I was skeptical of your abilities and intentions. Coming from the political scene, it is indeed hard to trust new people. ")
			18.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "I understand. I am honored that you trusted me in the end. ")
			19.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
				await start_type_text(dialog_label, "You earned it. Pipe by pipe, drain by drain, system by system, you fixed the problem. ")
			20.0:
				await start_type_text(dialog_label, "My father used to say, “Leadership is about leaving things better than when you found them.” I thought I failed at that, but I think I’ve finally started to live up to it. ")
			21.0:
				await start_type_text(dialog_label, "I trusted the right person to fix what I couldn’t.")
			22.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "I’m just doing my job, ma’am. ")
			23.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
				await start_type_text(dialog_label, "If the system ever fails, I’m calling you first.  ")
			24.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Fair enough, I’ll answer. ")
			25.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/VICKY.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "VICKY LY"
				await start_type_text(dialog_label, "You gave this city back its dignity. So… thank you, Engineer Dimayuga. Sincerely, from Sincerra City. ")
			26.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/PEDRO.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "PAPA P"
				await start_type_text(dialog_label, "Engineer Dimayuga, as I live and breathe! Once again, you have proven why your name is trusted. You have done a wonderful job in Sincerra City.")
			27.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Thank you, Governor. Mayor Ly was very accommodating and also one of the reasons for the success–")
			28.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/PEDRO.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "PAPA P"
				await start_type_text(dialog_label, "And we delivered it! When we bring in the right people, when we make the right choices, things like these happen. ")
			29.0:
				await start_type_text(dialog_label, "You know, I’ve always valued efficiency. That’s why our project stands out!")
			30.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Right. I just hope that the people feel the difference. ")
			31.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/PEDRO.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "PAPA P"
				await start_type_text(dialog_label, "Don’t worry, they do. Just like here, we’ll do the same for the next city. Next stop, Tigasulo City! It will be a bigger milestone for us. ")
			32.0:
				fade_rect.mouse_filter = 2
				for ui in $"../UI/Control".get_children():
					if not ui is AudioStreamPlayer and ui.name != "Dialouge":
						ui.visible = false
				var tween2 = create_tween()
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ZERO, 0.25 * 0.4)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
				$"../UI/Control/Dialouge".visible = false
				await get_tree().create_timer(2).timeout
				is_game_over = true
				act += 1
				await fade("out")
				get_tree().reload_current_scene()
				
		if index != 13.0:
			runThrough = true
	elif act == 2:
		fade_rect.mouse_filter = 2
		for ui in $"../UI/Control".get_children():
			if not ui is AudioStreamPlayer and ui.name != "Dialouge":
				ui.visible = false
		$"../UI/Control/Dialouge".visible = true
		var tween = create_tween()
		tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE, 0.25 * 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		runThrough = false
		match index:
			0.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Tigasulo City. It’s quieter than expected. It has no towering buildings or busy interactions. It feels so… steady.")
			1.0:
				await start_type_text(dialog_label, "The governor stated that this project would be a bigger milestone. From the looks of it, flooding isn’t the only problem here, but also the outdated system. ")
			2.0:
				await start_type_text(dialog_label, "If Sincerra can rise, so can Tigasulo! Even if the challenge is heavier, I won’t back down.")
			3.0:
				await start_type_text(dialog_label, "Mayor Francisco Velasco… Let’s see what kind of leader you are. ")
				runThrough = false
				await fade("out", 1)
				dialog_label.text = ""
				dialougeIndex += 1
			4.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/FRANCISCO.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "KIKO"
				await fade("in", 1)
				await start_type_text(dialog_label, "[He is the mayor of Tigasulo City. Using his previous experience as a barangay captain, he worked his way up to become a mayor. Due to this, he is set in his own ways, not being open-minded to new things and changes.]")
			5.0:
				await start_type_text(dialog_label, "Welcome to Tigasulo City! We may not have the tallest buildings or the flashiest gadgets, but what you see here is actual living. We’ve stood strong for years, even without all that high-tech fuss. ")
			6.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Thank you, Mayor Velasco! I’m ready to help.")
			7.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/FRANCISCO.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "KIKO"
				await start_type_text(dialog_label, "Good. I’ve heard about what you have done to Sincerra… and you’ll find things to be different here. We don’t want big, flashy changes. The city just needs a little fixing. ")
			8.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Yes, I understand. I will follow what the city needs. ")
			9.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/FRANCISCO.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "KIKO"
				await start_type_text(dialog_label, "I appreciate that. You see, I have been running this place for a long time and I have decades of experience as a leader. Starting as a barangay captain, I worked my way up. ")
			10.0:
				await start_type_text(dialog_label, "So, you have to trust me. I know what the city needs and more importantly… what it doesn’t.")
			11.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Of course. What do you want me to do then?")
			12.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/FRANCISCO.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "KIKO"
				await start_type_text(dialog_label, "Fix the flooding. But listen carefully, don’t go around changing the city’s layout. No tearing things down just to make room for some modern invention. ")
			13.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Sure. This means I will be given limited space to work with, right? ")
			14.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/FRANCISCO.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "KIKO"
				await start_type_text(dialog_label, "Exactly. If you’re really as skilled as they say, you can do it without changing Tigasulo.")
			15.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Yes, I will do my best. ")
			16.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/FRANCISCO.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "KIKO"
				await start_type_text(dialog_label, "I’m counting on you, Engineer. Don’t taint this city’s long-standing history. ")
			17.0:
				var tween2 = create_tween()
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ZERO, 0.25 * 0.4)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
				for ui in $"../UI/Control".get_children():
					if not ui is AudioStreamPlayer and ui.name != "Dialouge":
						ui.visible = true
				$"../UI/Control/Dialouge".visible = false
				var storms = {
					"3": "light",
					"7": "medium",
					"8": "demolish",
					"11": "heavy"
				}
				start_game(storms)
			18.0:
				if current_tool != "none":
					current_tool = "none"
					var slide_distance = $"../UI/Control/leftSelect".size.x
					var target_x = $"../UI/Control/leftSelect".position.x - slide_distance
					var target_position = Vector2(target_x, $"../UI/Control/leftSelect".position.y)
					var duration = 0.3

					var tweenSelect = create_tween()
					tweenSelect.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
						
					tweenSelect.tween_property($"../UI/Control/leftSelect", "position", target_position, duration)
					
				var tween2 = create_tween()
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE, 0.25 * 0.4)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
					
				await start_type_text(dialog_label, "Well… I suppose the system is working. The streets are clear and the people seem happy. Not bad, Engineer. Not bad at all. ")
			19.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "I’m glad the system worked out, Mayor. The people here seem relieved. ")
			20.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/FRANCISCO.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "KIKO"
				await start_type_text(dialog_label, "Relieved? I appreciate it… not that I needed help, of course. I’ve handled worse as a barangay captain. Knee-deep in water, no machines, just a shovel and sheer willpower. ")
			21.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "I’m sure you did great back then, Mayor Velasco.")
			22.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/FRANCISCO.PNG")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "KIKO"
				await start_type_text(dialog_label, "Hmph… I still could have done it. If I was still in my prime. But, sure, you did fine. I’ll give you that. ")
			23.0:
				$"../UI/Control/Dialouge/TextureRect".texture = load("res://Sprites/Characters/ALONA.png")
				$"../UI/Control/Dialouge/MarginContainer/VBoxContainer/name/Label".text = "ALONA"
				await start_type_text(dialog_label, "Thank you! I’m glad I could help. ")
			_:
				fade_rect.mouse_filter = 2
				for ui in $"../UI/Control".get_children():
					if not ui is AudioStreamPlayer and ui.name != "Dialouge":
						ui.visible = false
				var tween2 = create_tween()
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ONE * 1.1, 0.25 * 0.6)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tween2.tween_property($"../UI/Control/Dialouge", "scale", Vector2.ZERO, 0.25 * 0.4)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
				$"../UI/Control/Dialouge".visible = false
				await get_tree().create_timer(2).timeout
				is_game_over = true
				act += 1
				await fade("out")
				get_tree().reload_current_scene()
				
		if index != 17.0:
			runThrough = true
	elif act == 3:
		fade_rect.mouse_filter = 2
		await get_tree().create_timer(10).timeout
		flood_treshold = 2
		phase = "storm"
		flood_rise_speed = 2.05
		
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
	
func start_game(storm_months):
	fade_rect.mouse_filter = 2
	while current_month <= 12:
		phase = "building"
		print(str(current_month) + "th month started")
		if storm_months.has(str(current_month)):
			phase = "storm"
			match storm_months[str(current_month)]:
				"light":
					flood_rise_speed = 1.0
				"medium":
					flood_rise_speed = 1.5
				"heavy":
					flood_rise_speed = 2.06
					can_break = true
				"demolish":
					demolish_event()
				"birthday":
					money*=0.5
			await phase_changed
		else:
			await get_tree().create_timer(month_duration).timeout
		current_month += 1
	
	dialougeIndex += 1
	
func storm_pass(node, prevSize, prevPos):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(node.mesh, "size:y", 0.1, 1.5)
	tween.tween_property(node, "position:y", 0.35, 1.5)
	
	await tween.finished
	node.mesh.size.y = prevSize
	node.position.y = prevPos
	node.visible = false
	
func destroy(type, obj):
	var objPos = Vector2(obj.global_position.x, obj.global_position.z)
	if type == "drain" and drains.has(str(objPos)):
		var parts = map.get_node("Placed/surface").get_children()
		for part in parts:
			var pos = Vector2(part.global_position.x, part.global_position.z)
			if pos == objPos:
				part.reparent(map.get_node("Placed/clogged"))
				drains[str(objPos)][0] = false
	
	elif type == "pipe" and pipes.has(str(objPos)):
		var parts = map.get_node("Placed/under").get_children()
		for part in parts:
			var pos = Vector2(part.global_position.x, part.global_position.z)
			if pos == objPos:
				part.get_node("mesh").transparency = 0.8
				for child in part.get_children():
					if child is Area3D:
						child.monitoring = false
						child.monitorable = false
	
	var icon = warningIcon.instantiate()
	icon.name = "warningIcon"
	icon.position = Vector3(objPos.x, 1.0, objPos.y)
	obj.add_child(icon)

func demolish_event(percentage: float = 0.75):
	var amt = floor(pipes.size() * percentage)
	var under = map.get_node("Placed/under")
	
	for i in range(amt):
		var chosen = under.get_children().pick_random()
		if chosen.name == "output":
			i -= 1  
			continue
		destroy("pipe", chosen)
		
func _update_ui():
	if has_node("../UI"):
		var ui = get_node("../UI")
		ui.update_ui(money, current_month, current_tool, phase)
