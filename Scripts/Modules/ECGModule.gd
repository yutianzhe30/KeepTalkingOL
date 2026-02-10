extends "res://Scripts/Modules/BaseModule.gd"

@onready var ecg_line: Line2D = $PanelContainer/VBoxContainer/ECGDisplayRect/ECGLine
@onready var waveform_selector: OptionButton = $PanelContainer/VBoxContainer/HBoxContainer/WaveformSelector
@onready var heart_rate_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/HeartRateLabel
@onready var ecg_display_rect: ColorRect = $PanelContainer/VBoxContainer/ECGDisplayRect

enum WaveformType { NORMAL, TACHYCARDIA, VENTRICULAR_FIBRILLATION }

var current_waveform_type: WaveformType = WaveformType.NORMAL
var display_width: float
var display_height: float
var time_scale: float = 0.05
var simulation_time: float = 0.0
var cycle_duration: float = 2.0

var points_buffer: Array[Vector2] = []
var rng = RandomNumberGenerator.new()
var vfib_last_y: float = 0.0


func _ready():
	display_width = ecg_display_rect.size.x - 20
	display_height = ecg_display_rect.size.y - 20
	rng.randomize()
	
	waveform_selector.add_item("Normal", WaveformType.NORMAL)
	waveform_selector.add_item("Tachycardia", WaveformType.TACHYCARDIA)
	waveform_selector.add_item("Ventricular Fibrillation", WaveformType.VENTRICULAR_FIBRILLATION)
	waveform_selector.item_selected.connect(on_waveform_selected)
	waveform_selector.select(WaveformType.NORMAL)
	
	set_waveform_type(current_waveform_type)
	
	ecg_line.clear_points()
	points_buffer.clear()

func _process(delta):
	simulation_time += delta
	update_ecg_waveform()
	
	if simulation_time >= cycle_duration:
		simulation_time = 0.0
		points_buffer.clear()
		ecg_line.clear_points()

func on_waveform_selected(index: int):
	var selected_type = waveform_selector.get_item_id(index)
	set_waveform_type(selected_type)

func set_waveform_type(type: WaveformType):
	current_waveform_type = type
	points_buffer.clear()
	ecg_line.clear_points()
	simulation_time = 0.0
	vfib_last_y = 0.0

func update_ecg_waveform():
	var new_point_raw_x = simulation_time / time_scale
	var cycle_raw_x_end = cycle_duration / time_scale
	
	if (points_buffer.is_empty() or points_buffer.back().x < new_point_raw_x) and new_point_raw_x <= cycle_raw_x_end:
		var new_point_y = get_waveform_value(simulation_time)
		points_buffer.append(Vector2(new_point_raw_x, new_point_y))

	var scale_factor_x = display_width / cycle_raw_x_end if cycle_raw_x_end > 0 else 1.0

	var display_points = []
	for p in points_buffer:
		var scaled_x = p.x * scale_factor_x
		display_points.append(Vector2(scaled_x, p.y))
	
	ecg_line.set_points(display_points)
	
	match current_waveform_type:
		WaveformType.NORMAL:
			heart_rate_label.text = "HR: ~75 bpm"
		WaveformType.TACHYCARDIA:
			heart_rate_label.text = "HR: ~160 bpm"
		WaveformType.VENTRICULAR_FIBRILLATION:
			heart_rate_label.text = "HR: VFib"

# --- Main Waveform Value Calculation ---
func get_waveform_value(time: float) -> float:
	var value = 0.0 # Normalized value in [-1, 1] range
	match current_waveform_type:
		WaveformType.NORMAL:
			value = _generate_normal_ecg_value(time)
		WaveformType.TACHYCARDIA:
			value = _generate_tachycardia_ecg_value(time)
		WaveformType.VENTRICULAR_FIBRILLATION:
			value = _generate_vfib_ecg_value(time)
	
	# Scale normalized value to display height and center it.
	# A negative value results in an UPWARD line direction.
	return (value * display_height * 0.4) + (display_height * 0.5)

# --- Waveform Generation Functions (Return Normalized Value) ---

func _generate_normal_ecg_value(time: float) -> float:
	var bpm = 75.0
	var beat_interval = 60.0 / bpm
	var cycle_time = fmod(time, beat_interval)
	var y = 0.0

	# P wave (atrial contraction)
	if cycle_time > 0.1 and cycle_time < 0.2:
		y = -5.0 * sin(PI * (cycle_time - 0.1) / 0.1)
	# QRS complex (ventricular contraction)
	elif cycle_time >= 0.2 and cycle_time < 0.25:
		y = 40.0 * (cycle_time - 0.2) / 0.05
	elif cycle_time >= 0.25 and cycle_time < 0.3:
		y = 40.0 - 80.0 * (cycle_time - 0.25) / 0.05
	elif cycle_time >= 0.3 and cycle_time < 0.35:
		y = -40.0 + 40.0 * (cycle_time - 0.3) / 0.05
	# T wave (ventricular repolarization)
	elif cycle_time > 0.5 and cycle_time < 0.65:
		y = -10.0 * sin(PI * (cycle_time - 0.5) / 0.15)
	
	return y / 40.0 # Normalize based on R-peak of 40

func _generate_tachycardia_ecg_value(time: float) -> float:
	var bpm = 160.0
	var beat_interval = 60.0 / bpm
	var cycle_time = fmod(time, beat_interval)
	var y = 0.0
	
	if cycle_time < 0.1: 
		y = -5.0 * sin(PI * cycle_time / 0.1) # P wave
	elif cycle_time >= 0.1 and cycle_time < 0.2: # QRS complex
		var t = (cycle_time - 0.1) / 0.1
		y = 40.0 * sin(2 * PI * t - PI/2) # Simplified QRS as a sine wave
	elif cycle_time > 0.25 and cycle_time < 0.35: 
		y = -10.0 * sin(PI * (cycle_time-0.25)/0.1) # T wave

	return y / 40.0 # Normalize based on R-peak of 40

func _generate_vfib_ecg_value(_time: float) -> float:
	# This logic is stateful and doesn't use the time parameter.
	var noise = rng.randf_range(-15.0, 15.0)
	# Lerp for smoothing, makes it look more organic than pure noise
	var smooth_y = lerp(vfib_last_y, noise, 0.4)
	vfib_last_y = smooth_y
	
	return smooth_y / 15.0 # Normalize to [-1, 1] range
