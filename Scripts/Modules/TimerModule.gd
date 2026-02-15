extends "res://Scripts/Modules/BaseModule.gd"

@onready var label = $Label
@onready var timer_node = $Timer

var time_remaining: float = 300.0 # 5 minutes default
var is_running: bool = false
var last_tick_second: int = -1

func _ready():
	update_display()
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
	# Format: MM:SS:MS
	var minutes = floor(time_remaining / 60)
	var seconds = floor(fmod(time_remaining, 60))
	var millis = floor(fmod(time_remaining, 1) * 100)
	
	# %02d used for padding with zeros
	label.text = "%02d:%02d:%02d" % [minutes, seconds, millis]

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

func explode():
	stop_timer()
	strike() # Or a dedicated GAME OVER signal
	print("BOOM: Time ran out!")
