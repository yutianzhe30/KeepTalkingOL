extends "res://Scripts/Modules/BaseModule.gd"

@onready var label = $VBoxContainer/TimerContainer/Label
@onready var strike_label = $VBoxContainer/StrikeContainer/StrikeLabel
@onready var timer_node = $Timer

var time_remaining: float = 300.0 # 5 minutes default
var is_running: bool = false
var last_tick_second: int = -1
var strike_count: int = 0

func _ready():
	# Apply Global Colors
	label.add_theme_color_override("font_color", GlobalColors.COLOR_RED)
	strike_label.add_theme_color_override("font_color", GlobalColors.COLOR_RED)
	
	$VBoxContainer/TimerContainer/BackgroundLabel.add_theme_color_override("font_color", GlobalColors.COLOR_TRANSPARENT_RED)
	$VBoxContainer/StrikeContainer/BackgroundLabel.add_theme_color_override("font_color", GlobalColors.COLOR_TRANSPARENT_RED)

	update_display()
	update_strike_display()
	# Optional: Start automatically for testing
	start_timer()

func _process(delta):
	if is_running and time_remaining > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			explode()
		
		update_display()
		check_sound_tick()

func update_display():
	# Format: MM:SS
	var minutes = floor(time_remaining / 60)
	var seconds = floor(fmod(time_remaining, 60))
	# var millis = floor(fmod(time_remaining, 1) * 100) # Removed millis for 7-segment look if preferred, or keep
	
	# %02d used for padding with zeros
	label.text = "%02d:%02d" % [minutes, seconds]

func update_strike_display():
	var strike_text = ""
	for i in range(strike_count):
		strike_text += "-"
	strike_label.text = strike_text

func check_sound_tick():
	# Trigger sound every second
	var current_second = ceil(time_remaining)
	if current_second != last_tick_second:
		last_tick_second = current_second
		play_tick_sound()

func play_tick_sound():
	# TODO: Connect this to an AudioStreamPlayer
	# print("Tick") 
	pass

func start_timer():
	is_running = true

func stop_timer():
	is_running = false

func add_time_penalty(seconds: float) -> void:
	time_remaining = max(0.0, time_remaining - seconds)
	update_display()
	if time_remaining <= 0.0:
		explode()

func add_strike() -> void:
	strike_count += 1
	update_strike_display()

func explode():
	stop_timer()
	strike() # Or a dedicated GAME OVER signal
	print("BOOM: Time ran out!")
