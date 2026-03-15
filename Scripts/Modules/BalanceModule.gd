extends "res://Scripts/Modules/BaseModule.gd"

@onready var ball = $ReferenceRect/Ball
@onready var boundary = $ReferenceRect
@onready var prompt_label = $ReferenceRect/PromptLabel
@onready var target_area = $ReferenceRect/TargetArea

func _init() -> void:
	is_solvable = false

var velocity: Vector2 = Vector2.ZERO
var position_offset: Vector2 = Vector2.ZERO # Position relative to center
var is_active: bool = true
var has_started: bool = false
var time_to_start: float = 3.0
var balance_time: float = 0.0

# Mobile controls
var base_accelerometer: Vector3 = Vector3.ZERO
var is_accelerometer_available: bool = false

# Physics Constants
const REPULSION_FORCE: float = 100.0 # Pushes ball away from center
const INPUT_FORCE: float = 400.0 # Player control strength
const DRAG: float = 1.0 # Air resistance
const RADIUS: float = 10.0 # Ball radius (half size)
const MAX_SPEED: float = 140.0 # Cap speed to give user a chance
const TARGET_RADIUS: float = 20.0 # Size of the balance target area

# Color Constants
const COLOR_RED_FLASH = Color(1, 0, 0, 1)
const COLOR_RED_DIM = Color(0.3, 0, 0, 1)
const COLOR_GREEN_SOLVED = Color(0, 1, 0, 1)

func _ready():
	if target_area:
		target_area.custom_minimum_size = Vector2(TARGET_RADIUS * 2, TARGET_RADIUS * 2)
		target_area.size = Vector2(TARGET_RADIUS * 2, TARGET_RADIUS * 2)

	# Connect to all other modules to listen for solves
	if get_parent():
		for module in get_parent().get_children():
			if module is BaseModule and module != self:
				module.module_solved.connect(_on_other_module_solved)
	_start_sequence()

func _start_sequence():
	time_to_start = 3.0
	balance_time = 0.0
	is_active = false
	has_started = false
	velocity = Vector2.ZERO
	position_offset = Vector2.ZERO
	
	# Calibrate the accelerometer when the module starts
	# Use WebInput to support mobile browsers alongside native platforms
	var rot = WebInput.get_rotation() if WebInput else Vector3.ZERO
	if rot != Vector3.ZERO:
		base_accelerometer = rot
		is_accelerometer_available = true
		print("BalanceModule: Rotation calibrated to: ", rot)
	else:
		print("BalanceModule: Rotation not detected or zero.")

	prompt_label.visible = true
	boundary.border_color = COLOR_RED_FLASH

func _on_other_module_solved():
	if state == ModuleState.SOLVED and false == is_active:
		if randf() <= 0.33:
			_set_state(ModuleState.IDLE)
			_update_led_for_state()
			_start_sequence()

func _process(delta):
	if state == ModuleState.SOLVED:
		return
	var center = boundary.size / 2.0
	if not has_started:
		velocity = Vector2.ZERO
		position_offset = Vector2.ZERO
		ball.position = center - (ball.size / 2.0)
		time_to_start -= delta
		# Flash border
		var time_msec = Time.get_ticks_msec()
		if sin(time_msec / 100.0) > 0:
			boundary.border_color = COLOR_RED_FLASH
		else:
			boundary.border_color = COLOR_RED_DIM
			
		if time_to_start <= 0:
			prompt_label.visible = false
			boundary.border_color = COLOR_RED_DIM
			
			if AudioManager:
				AudioManager.play_strike()
			if is_accelerometer_available:
				base_accelerometer = WebInput.get_rotation()
			var random_angle = randf() * TAU
			velocity = Vector2.from_angle(random_angle) * 50.0
			is_active = true
			has_started = true
	# 3. Update Visuals
	center = boundary.size / 2.0
	ball.position = center + position_offset - (ball.size / 2.0)
	
	if target_area:
		target_area.position = center - (target_area.size / 2.0)
	
	if !is_active:
		return
		
	# 1. Calculate Forces
	var force = Vector2.ZERO
	
	# Repulsion (Unstable Equilibrium): Pushes away from center
	# The further out you are, the stronger the pull
	if position_offset.length() > 0:
		force += position_offset.normalized() * (position_offset.length() * 2.0)
		
	# Input (Counter-force)
	var input = Input.get_vector("left", "right", "up", "down")

	if is_accelerometer_available:
		var current_rot = WebInput.get_rotation() if WebInput else Vector3.ZERO
		var rot_diff = current_rot - base_accelerometer

		# Rotation (alpha, beta, gamma converted from 0-360 degrees to radians).
		# By testing, beta maps to pitching forward/back, gamma maps to rolling left/right.
		# WebInput already did deg_to_rad()
		# Multiplication factors might need tweaking based on how sensitive you want it
		var accel_input = Vector2(rot_diff.y, rot_diff.x) * 4.0
		
		# Combine keyboard and accelerometer
		input += accel_input

	# Clamp input length so we don't go super fast
	if input.length() > 1.0:
		input = input.normalized()
	force += input * INPUT_FORCE
	
	# 2. Integrate Physics
	velocity += force * delta
	velocity -= velocity * DRAG * delta # Damping
	
	# Cap the speed
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
		
	position_offset += velocity * delta
	
	# 4. Check Collision (Fail Condition)
	check_boundary()
	
	# 5. Check Balanced (Win Condition)
	if has_started and state != ModuleState.SOLVED:
		if position_offset.length() < TARGET_RADIUS:
			balance_time += delta
			if balance_time >= 1.0:
				print("Balance Module Balanced! Solving.")
				is_active = false
				velocity = Vector2.ZERO
				position_offset = Vector2.ZERO
				prompt_label.visible = false
				boundary.border_color = COLOR_GREEN_SOLVED # Green border
				solve()
		else:
			balance_time = 0.0

func check_boundary():
	var half_size = boundary.size / 2.0
	var bounds_x = half_size.x - RADIUS
	var bounds_y = half_size.y - RADIUS
	
	if abs(position_offset.x) > bounds_x or abs(position_offset.y) > bounds_y:
		strike_module()
func get_debug_info() -> String:
	return "Balance Module: Keep the ball centered!"

func strike_module():
	if !is_active: return
	print("Balance Module Failed!")
	strike()
	has_started = false
	time_to_start = 3.0
