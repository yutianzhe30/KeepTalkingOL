extends "res://Scripts/Modules/BaseModule.gd"

signal timer_exploded

@onready var label = $VBoxContainer/TimerContainer/Label
@onready var strike_label = $VBoxContainer/StrikeContainer/StrikeLabel
@onready var timer_node = $Timer

var time_remaining: float = 300.0 # 5 minutes default
var is_running: bool = false
var last_tick_second: int = -1
var strike_count: int = 0

var last_display_total_seconds: int = -1
const TICK_SOUND = preload("res://Assets/Sound/tick.wav")

func _init() -> void:
	is_solvable = false

var tick_audio_player: AudioStreamPlayer

func _ready():
	# Apply Global Colors
	label.add_theme_color_override("font_color", GlobalColors.COLOR_RED)
	strike_label.add_theme_color_override("font_color", GlobalColors.COLOR_RED)
	
	$VBoxContainer/TimerContainer/BackgroundLabel.add_theme_color_override("font_color", GlobalColors.COLOR_TRANSPARENT_RED)
	$VBoxContainer/StrikeContainer/BackgroundLabel.add_theme_color_override("font_color", GlobalColors.COLOR_TRANSPARENT_RED)

	# Audio Setup
	tick_audio_player = AudioStreamPlayer.new()
	if TICK_SOUND:
		tick_audio_player.stream = TICK_SOUND
		add_child(tick_audio_player)
	else:
		push_warning("TimerModule: Could not load tick.wav")

	update_display()
	update_strike_display()

	set_process(is_running)
	# Optional: Start automatically for testing
	start_timer()

func _process(delta):
	if time_remaining > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			explode()
		
		update_display()
		check_sound_tick()

func update_display():
	var total_seconds = int(time_remaining)
	if total_seconds == last_display_total_seconds:
		return

	last_display_total_seconds = total_seconds

	# Format: MM:SS using integer math
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60

	# %02d used for padding with zeros
	label.text = "%02d:%02d" % [minutes, seconds]

func update_strike_display():
	var strike_text = ""
	for i in range(strike_count):
		strike_text += "-"
	strike_label.text = strike_text

func check_sound_tick():
	# Trigger sound every second
	var current_second = int(ceil(time_remaining))
	if current_second == last_tick_second:
		return

	last_tick_second = current_second
	play_tick_sound()

func play_tick_sound():
	if tick_audio_player and tick_audio_player.stream:
		tick_audio_player.play()

func start_timer():
	is_running = true
	set_process(true)

func stop_timer():
	is_running = false
	set_process(false)

func add_time_penalty(seconds: float) -> void:
	time_remaining = max(0.0, time_remaining - seconds)
	update_display()
	if time_remaining <= 0.0:
		explode()

func add_strike() -> void:
	strike_count += 1
	update_strike_display()
	if strike_count >= 3:
		explode()

func explode():
	if not is_running: return
	stop_timer()
	emit_signal("timer_exploded")
	print("BOOM: Bomb Exploded!")

func get_debug_info() -> String:
	var time_text = "00:00"
	if label != null:
		time_text = label.text
	return "Timer Module: %s, Strikes: %d" % [time_text, strike_count]
