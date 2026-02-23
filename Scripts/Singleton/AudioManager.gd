extends Node

var audio_players: Dictionary = {}
var sound_files = {
	"solve": "res://Assets/Sound/right.wav",
	"strike": "res://Assets/Sound/wrong.wav",
	"click": "res://Assets/Sound/click.wav"
}

func _ready() -> void:
	for key in sound_files:
		var stream = load(sound_files[key])
		if stream:
			var player = AudioStreamPlayer.new()
			player.stream = stream
			player.name = "AudioPlayer_" + key
			add_child(player)
			audio_players[key] = player
		else:
			push_warning("AudioManager: Could not load sound file " + sound_files[key])
			
	# Connect to node added signal to inject click sound into all buttons
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		# Connect to mouse entered (hover) if desired, but we stick to pressed for now
		if not node.pressed.is_connected(_on_button_pressed):
			node.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	play_sound("click")

func play_sound(sound_name: String) -> void:
	if audio_players.has(sound_name):
		audio_players[sound_name].play()
	else:
		push_warning("AudioManager: Sound not found " + sound_name)

func play_solve() -> void:
	play_sound("solve")
	
func play_strike() -> void:
	play_sound("strike")
