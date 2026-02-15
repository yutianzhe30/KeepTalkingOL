extends "res://Scripts/Modules/BaseModule.gd"

# Medical ECG Module ("On-Call")
# The user sees a patient's heart rhythm and must administer the correct treatment.

@onready var ecg_line: Line2D = $PanelContainer/VBoxContainer/ECGDisplayRect/ECGLine
@onready var heart_rate_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/HeartRateLabel
@onready var ecg_display_rect: ColorRect = $PanelContainer/VBoxContainer/ECGDisplayRect

# Controls (To be linked in _ready or via scene references)
@onready var energy_slider: HSlider = $PanelContainer/VBoxContainer/HBoxContainer/EnergySlider
@onready var dosage_slider: HSlider = $PanelContainer/VBoxContainer/HBoxContainer/DosageSlider
@onready var administer_btn: Button = $PanelContainer/VBoxContainer/HBoxContainer/AdministerButton
@onready var energy_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/EnergyLabel
@onready var dosage_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/DosageLabel

enum RhythmType {
	SINUS_TACH, # Normal but fast
	VFIB, # Chaos
	ASYSTOLE, # Flatline
	STEMI, # Tombstone (Elevated ST)
	FLUTTER # Sawtooth
}

var current_rhythm: RhythmType = RhythmType.SINUS_TACH
var display_width: float
var display_height: float
var time_scale: float = 0.05
var simulation_time: float = 0.0
var cycle_duration: float = 2.0 # Seconds per screen width approx

var points_buffer: Array[Vector2] = []
var rng = RandomNumberGenerator.new()
var vfib_last_y: float = 0.0

func _ready():
	display_width = ecg_display_rect.size.x - 20
	display_height = ecg_display_rect.size.y - 20
	rng.randomize()
	
	administer_btn.pressed.connect(_on_administer_pressed)
	energy_slider.value_changed.connect(_on_energy_changed)
	dosage_slider.value_changed.connect(_on_dosage_changed)
	
	# Start with a random rhythm
	_start_new_patient()
	
	set_process(true)

func _start_new_patient():
	current_rhythm = RhythmType.values().pick_random()
	points_buffer.clear()
	ecg_line.clear_points()
	simulation_time = 0.0
	
	# Update Label Hint (for debug or until user learns)
	# heart_rate_label.text = "Patient: " + RhythmType.keys()[current_rhythm]
	print("New Patient Rhythm: ", RhythmType.keys()[current_rhythm])
	
	# Reset Sliders? No, keeps previous setting maybe? Or reset for fairness.
	# energy_slider.value = 0
	# dosage_slider.value = 0

func _process(delta):
	simulation_time += delta
	_update_ecg_waveform()
	
	if simulation_time >= cycle_duration:
		simulation_time = 0.0
		points_buffer.clear()
		ecg_line.clear_points()

func _update_ecg_waveform():
	var new_point_raw_x = simulation_time / time_scale
	var cycle_raw_x_end = cycle_duration / time_scale
	
	# Add points
	if (points_buffer.is_empty() or points_buffer.back().x < new_point_raw_x) and new_point_raw_x <= cycle_raw_x_end:
		var new_point_y = _get_waveform_value(simulation_time)
		points_buffer.append(Vector2(new_point_raw_x, new_point_y))

	# Scale for display
	var scale_factor_x = display_width / cycle_raw_x_end if cycle_raw_x_end > 0 else 1.0

	var display_points = []
	for p in points_buffer:
		var scaled_x = p.x * scale_factor_x
		display_points.append(Vector2(scaled_x, p.y))
	
	ecg_line.set_points(display_points)
	_update_status_label()

func _update_status_label():
	# Display HR based on rhythm
	match current_rhythm:
		RhythmType.SINUS_TACH: heart_rate_label.text = "HR: 155"
		RhythmType.VFIB: heart_rate_label.text = "HR: ??? (VFib)"
		RhythmType.ASYSTOLE: heart_rate_label.text = "HR: 0"
		RhythmType.STEMI: heart_rate_label.text = "HR: 88"
		RhythmType.FLUTTER: heart_rate_label.text = "HR: 300 (A)" # Atrial rate high

func _on_energy_changed(value):
	energy_label.text = "%d J" % value

func _on_dosage_changed(value):
	dosage_label.text = "%d mg" % value

func _on_administer_pressed():
	var energy = energy_slider.value
	var dosage = dosage_slider.value
	
	print("Administering: Energy=", energy, " Dosage=", dosage, " for ", RhythmType.keys()[current_rhythm])
	
	if _check_treatment(energy, dosage):
		print("Treatment Effective!")
		solve()
	else:
		print("Treatment Failed! Malpractice!")
		strike()
		_start_new_patient()

func _check_treatment(e: float, d: float) -> bool:
	# Tolerance for sliders
	var _e_tol = 10.0
	var d_tol = 5.0
	
	match current_rhythm:
		RhythmType.SINUS_TACH:
			# Discharge -> 0, 0
			return e == 0 and d == 0
		RhythmType.VFIB:
			# Shock -> Max Energy (assume 200 or 360, let's say >= 200)
			return e >= 200 and d == 0
		RhythmType.ASYSTOLE:
			# Pray -> 0, 0
			return e == 0 and d == 0
		RhythmType.STEMI:
			# Cath Lab -> Dosage 90 (Door-to-balloon)
			return e == 0 and abs(d - 90) <= d_tol
		RhythmType.FLUTTER:
			# Adenosine -> Dosage 6
			return e == 0 and abs(d - 6) <= d_tol
			
	return false

# --- Waveform Generation ---

func _get_waveform_value(time: float) -> float:
	var val = 0.0
	match current_rhythm:
		RhythmType.SINUS_TACH: val = _gen_sinus(time, 155.0)
		RhythmType.VFIB: val = _gen_vfib(time)
		RhythmType.ASYSTOLE: val = _gen_asystole(time)
		RhythmType.STEMI: val = _gen_stemi(time)
		RhythmType.FLUTTER: val = _gen_flutter(time)
	
	# Scale to screen height
	return (val * display_height * 0.4) + (display_height * 0.5)

func _gen_sinus(time: float, bpm: float) -> float:
	var interval = 60.0 / bpm
	var t = fmod(time, interval)
	var y = 0.0
	
	# Simple P-QRS-T approximation
	if t < 0.1: y = -5.0 * sin(PI * t / 0.1) # P
	elif t < 0.15: y = 40.0 * (t - 0.1) / 0.05 # QRS Up
	elif t < 0.2: y = 40.0 - 80.0 * (t - 0.15) / 0.05 # QRS Down
	elif t < 0.25: y = -40.0 + 40.0 * (t - 0.2) / 0.05 # QRS Back
	elif t > 0.35 and t < 0.5: y = -10.0 * sin(PI * (t - 0.35) / 0.15) # T
	
	return y / 40.0

func _gen_vfib(_time: float) -> float:
	var noise = rng.randf_range(-1.0, 1.0)
	vfib_last_y = lerp(vfib_last_y, noise, 0.2)
	return vfib_last_y

func _gen_asystole(_time: float) -> float:
	return rng.randf_range(-0.05, 0.05) # Flatline with noise

func _gen_stemi(time: float) -> float:
	# Sinus but with elevated ST
	var bpm = 80.0
	var interval = 60.0 / bpm
	var t = fmod(time, interval)
	var y = 0.0
	
	if t < 0.1: y = -5.0 * sin(PI * t / 0.1) # P
	elif t < 0.15: y = 40.0 * (t - 0.1) / 0.05 # QRS Up
	elif t < 0.2: y = 40.0 - 60.0 * (t - 0.15) / 0.05 # QRS Down (Not all way down)
	elif t >= 0.2 and t < 0.4:
		# ST Elevation (Tombstone)
		# Starts high (-20) and arches down
		y = -20.0 + 10.0 * sin(PI * (t - 0.2) / 0.2)
	
	return y / 40.0

func _gen_flutter(time: float) -> float:
	# Sawtooth waves between QRS
	var bpm = 75.0 # Ventricular rate
	var interval = 60.0 / bpm
	var t = fmod(time, interval)
	
	# Base Sawtooth (Atrial Flutter) - fast constant wave
	var flutter_freq = 5.0 # Hz (300 bpm)
	var flutter_y = abs(fmod(time * flutter_freq, 1.0) - 0.5) * 2.0 - 0.5 # -0.5 to 0.5 triangle
	flutter_y *= 10.0 # Amplitude
	
	var qrs_y = 0.0
	if t < 0.05: qrs_y = 40.0 * t / 0.05
	elif t < 0.1: qrs_y = 40.0 - 80.0 * (t - 0.05) / 0.05
	elif t < 0.15: qrs_y = -40.0 + 40.0 * (t - 0.1) / 0.05
	
	return (flutter_y + qrs_y) / 40.0
