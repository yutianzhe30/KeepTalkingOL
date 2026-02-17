extends "res://Scripts/Modules/BaseModule.gd"

# Radio / Frequency Module
# Tune to the correct frequency to solve.
# Rule: Target = First Digit of Serial + 90.0 MHz.

@onready var frequency_label: Label = $PanelContainer/VBoxContainer/ControlsContainer/FrequencyLabel
@onready var waveform_line: Line2D = $PanelContainer/VBoxContainer/OscilloscopeDisplay/WaveformLine
@onready var tuner_slider: HSlider = $PanelContainer/VBoxContainer/ControlsContainer/TunerSlider
@onready var transmit_btn: Button = $PanelContainer/VBoxContainer/ControlsContainer/TransmitButton
@onready var static_player: AudioStreamPlayer = $StaticPlayer
@onready var signal_player: AudioStreamPlayer = $SignalPlayer
@onready var oscilloscope_bg: ColorRect = $PanelContainer/VBoxContainer/OscilloscopeDisplay

@onready var amp_slider: HSlider = $PanelContainer/VBoxContainer/ControlsContainer/AmpSlider
@onready var amp_label: Label = $PanelContainer/VBoxContainer/ControlsContainer/AmpLabel

# Config
const MIN_FREQ = 88.0
const MAX_FREQ = 108.0
const TOLERANCE_FREQ = 0.5
const TOLERANCE_AMP = 5.0

# State
var target_frequency: float = 90.0
var target_amplitude: float = 50.0
var current_frequency: float = 88.0
var current_amplitude: float = 0.0
var signal_strength: float = 0.0

# Waveform Visuals
var time: float = 0.0

# Audio Generation state
var current_phase: float = 0.0
var sample_hz: float = 44100.0
var static_stream: AudioStreamGeneratorPlayback
var signal_stream: AudioStreamGeneratorPlayback

func _ready():
	#super._ready() # BaseModule might handle some state
	tuner_slider.value_changed.connect(_on_frequency_changed)
	amp_slider.value_changed.connect(_on_amplitude_changed)
	transmit_btn.pressed.connect(_on_transmit_pressed)
	
	_setup_audio_streams()
	_determine_target()
	
	# Initial UI update
	_on_frequency_changed(tuner_slider.value)
	_on_amplitude_changed(amp_slider.value)

func _setup_audio_streams():
	var static_gen = AudioStreamGenerator.new()
	static_gen.mix_rate = 44100
	static_gen.buffer_length = 0.1
	static_player.stream = static_gen
	static_player.play()
	static_stream = static_player.get_stream_playback()
	
	var signal_gen = AudioStreamGenerator.new()
	signal_gen.mix_rate = 44100
	signal_gen.buffer_length = 0.1
	signal_player.stream = signal_gen
	signal_player.play()
	signal_stream = signal_player.get_stream_playback()
	
	sample_hz = static_gen.mix_rate

func _determine_target():
	# Rule: First Digit of Serial (1-9) + 90.0
	var first_digit = randi_range(1, 9)
	target_frequency = 90.0 + float(first_digit)
	
	# Amplitude Rule:
	# If Freq < 95.0 -> Amp 20
	# If Freq > 100.0 -> Amp 80
	# Else -> Amp 50
	if target_frequency < 95.0:
		target_amplitude = 20.0
	elif target_frequency > 100.0:
		target_amplitude = 80.0
	else:
		target_amplitude = 50.0
		
	print("RadioModule Target: Freq=", target_frequency, " Amp=", target_amplitude)

func _process(delta):
	if state == ModuleState.SOLVED:
		static_player.volume_db = -80.0
		signal_player.volume_db = -80.0
		return
		
	time += delta
	_update_signal_strength()
	_fill_audio_buffers()
	_update_waveform()

func _on_frequency_changed(freq: float):
	current_frequency = freq
	frequency_label.text = "%.1f MHz" % current_frequency

func _on_amplitude_changed(amp: float):
	current_amplitude = amp
	amp_label.text = "AMP: %d" % current_amplitude

func _update_signal_strength():
	var dist = abs(current_frequency - target_frequency)
	
	if dist < 2.0:
		var normalized_dist = dist / 2.0
		signal_strength = 1.0 - normalized_dist
		signal_strength = pow(signal_strength, 2)
	else:
		signal_strength = 0.0
		
	var static_vol = linear_to_db(max(0.01, 1.0 - signal_strength))
	var signal_vol = linear_to_db(max(0.01, signal_strength))
	
	static_player.volume_db = static_vol - 10.0
	signal_player.volume_db = signal_vol - 5.0

func _fill_audio_buffers():
	if not static_stream or not signal_stream: return
	
	# Filling Static Buffer
	var frames = static_stream.get_frames_available()
	if frames > 0:
		var buffer = PackedVector2Array()
		buffer.resize(frames)
		for i in range(frames):
			var s = randf_range(-1.0, 1.0) * 0.25
			buffer.set(i, Vector2(s, s))
		static_stream.push_buffer(buffer)
		
	# Filling Signal Buffer (Sine Tone)
	frames = signal_stream.get_frames_available()
	if frames > 0:
		var buffer = PackedVector2Array()
		buffer.resize(frames)
		var phase_inc = 300.0 / sample_hz
		
		# Morse 'dots' modulation could happen here, keeping it constant tone for now
		for i in range(frames):
			var s = sin(current_phase * TAU) * 0.3
			current_phase = fmod(current_phase + phase_inc, 1.0)
			buffer.set(i, Vector2(s, s))
		signal_stream.push_buffer(buffer)

func _update_waveform():
	var points = PackedVector2Array()
	var width = oscilloscope_bg.get_rect().size.x
	if width <= 0: width = 180.0 # Safety fallback
	
	var height = oscilloscope_bg.get_rect().size.y
	var center_y = height / 2.0
	var num_points = 50
	var step = width / float(num_points)
	
	for i in range(num_points + 1):
		var x = i * step
		var t_wave = time * 10.0 + (i * 0.5)
		
		# Visually, Amplitude Slider should affect wave height only?
		# Or should Signal Strength affect clarity, and Amp Slider affect overall size?
		# Let's say Amp Slider affects HEIGHT. Signal Strength affects NOISE vs SIGNAL mix.
		
		var amp_factor = current_amplitude / 100.0
		if amp_factor < 0.1: amp_factor = 0.1 # Minimum visibility
		
		var noise_amp = (1.0 - signal_strength) * (height * 0.2) * amp_factor
		var signal_amp = signal_strength * (height * 0.3) * amp_factor
		
		var y = center_y
		y += randf_range(-1.0, 1.0) * noise_amp
		y += sin(t_wave) * signal_amp
		
		points.append(Vector2(x, y))
		
	waveform_line.points = points
	waveform_line.default_color = Color(0.2, 0.8, 0.2).lerp(Color(0.2, 1.0, 0.2), signal_strength)

func _on_transmit_pressed():
	if state == ModuleState.SOLVED: return
	
	var freq_dist = abs(current_frequency - target_frequency)
	var amp_dist = abs(current_amplitude - target_amplitude)
	
	var freq_ok = freq_dist <= TOLERANCE_FREQ
	var amp_ok = amp_dist <= TOLERANCE_AMP
	
	if freq_ok and amp_ok:
		print("RadioModule: Transmission Verified!")
		solve()
	else:
		print("RadioModule: Invalid Transmission! FreqErr=", freq_dist, " AmpErr=", amp_dist)
		strike()
