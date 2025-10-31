extends Node

@onready var gridInterc = get_node("gridInteraction")
@onready var notif = get_node("../UI/notifManager")

# === Player Data ===
var money := 50000000:
	set(value):
		var polarity = "-" if money > value else "+"
		var text = polarity + "₱" + str(money-value)
		var color = Color(1.0, 0.0, 0.0, 1.0) if money > value else Color(0.0, 1.0, 0.0, 1.0)
		notif.notify(text, color)
		money = value
var level := 1
var current_tool := "none":
	set(value):
		current_tool = value
		gridInterc.update_obj(value)
			
# === Time ===
var current_month := 1
var max_months := 2
var month_duration := 30.0 
var month_timer := 0.0

# === Game Phases ===
var phase := "building" 
var is_game_over := false

# === Flood System ===
var flood_level := 0.0
var flood_rise_speed := 1.0
var drain_effectiveness := 0.0 
var flood_safe_threshold := 0.0

# === Pipe/Drain Data ===
var total_drains := 0
var working_drains := 0
var broken_drains := []

var objValues = {
	"drain": 300000,
	"pipe": 500000
}

# === Events ===
var random_break_chance := 0.1 

signal month_changed(month)
signal phase_changed(phase)
signal flood_updated(level)
signal drain_broken(drain)

func _ready():
	print("Tutorial started — month 1: building")
	_update_ui()
	emit_signal("phase_changed", phase)

func _process(delta):
	if is_game_over:
		return

	month_timer += delta
	if month_timer >= month_duration:
		_advance_month()
		month_timer = 0.0

	if phase == "storm":
		_process_storm(delta)

func _advance_month():
	current_month += 1
	emit_signal("month_changed", current_month)

	if current_month == 2:
		_start_storm_phase()
	elif current_month > max_months:
		_end_game()

func _start_storm_phase():
	phase = "storm"
	print("🌧 Storm Phase begins!")
	emit_signal("phase_changed", phase)

	# Initialize flood stats
	flood_level = 0.0
	flood_rise_speed = 1.0
	drain_effectiveness = working_drains * 0.2
	flood_safe_threshold = 0.0

func _process_storm(delta):
	# Randomly break drains
	for i in range(total_drains):
		if randf() < random_break_chance * delta:
			_break_random_drain()

	# Simulate flood rising and drain effect
	var reduction = working_drains * 0.05
	flood_level += (flood_rise_speed - reduction) * delta

	if flood_level < 0:
		flood_level = 0
	if flood_level > 10:
		_trigger_flood_gameover()

	emit_signal("flood_updated", flood_level)

func _break_random_drain():
	if total_drains <= 0:
		return
	var broken_id = "Drain" + str(randi_range(1, total_drains))
	if broken_id in broken_drains:
		return
	broken_drains.append(broken_id)
	working_drains = max(0, working_drains - 1)
	print("🚨", broken_id, "broken!")
	emit_signal("drain_broken", broken_id)

func repair_drain(id: String):
	if id in broken_drains:
		broken_drains.erase(id)
		working_drains += 1
		print("🔧", id, "repaired!")

func _trigger_flood_gameover():
	print("💦 City flooded! Game Over!")
	is_game_over = true

func _end_game():
	is_game_over = true
	print("✅ Tutorial complete!")

func _update_ui():
	if has_node("../UI"):
		var ui = get_node("../UI")
		ui.update_ui(money, current_month, current_tool, phase, flood_level)
