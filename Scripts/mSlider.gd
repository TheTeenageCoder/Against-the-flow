extends HSlider

@onready var music_player: AudioStreamPlayer = $"../../../../bgMusic"
var busMaster = AudioServer.get_bus_index("Master")

func _ready():
	# Set slider range to match dB scale
	min_value = -20  # Minimum volume (mute)
	max_value = 0  # Maximum volume (full volume)
	
	# Initialize slider to current music volume
	value = min_value/2 + music_player.volume_db
	
	connect("value_changed", _on_value_changed)
	

func _on_value_changed(new_value: float) -> void:
	music_player.volume_db = new_value
	
	if value == -20:
		AudioServer.set_bus_mute(busMaster, true)
	else:
		AudioServer.set_bus_mute(busMaster, false)
