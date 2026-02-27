extends "res://Scripts/Modules/BaseModule.gd"

@onready var ball = $ReferenceRect/Ball
@onready var boundary = $ReferenceRect
@onready var prompt_label = $ReferenceRect/PromptLabel

func _init() -> void:
	is_solvable = false

var velocity: Vector2 = Vector2.ZERO
var position_offset: Vector2 = Vector2.ZERO # Position relative to center
var is_active: bool = true
var has_started: bool = false
var time_to_start: float = 3.0
var balance_time: float = 0.0

# Physics Constants
const REPULSION_FORCE: float = 100.0 # Pushes ball away from center
const INPUT_FORCE: float = 400.0 # Player control strength
const DRAG: float = 1.0 # Air resistance
const RADIUS: float = 10.0 # Ball radius (half size)
const MAX_SPEED: float = 150.0 # Cap speed to give user a chance
const TARGET_RADIUS: float = 20.0 # Size of the balance target area

func _ready():
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
	
	prompt_label.visible = true
	boundary.border_color = Color(1, 0, 0, 1)

func _on_other_module_solved():
	if state == ModuleState.SOLVED:
		if randf() <= 0.33:
			_set_state(ModuleState.IDLE)
			_update_led_for_state()
			_start_sequence()

func _process(delta):
	if state == ModuleState.SOLVED:
		return
	var center = boundary.size / 2.0
	if not has_started:
		ball.position = center - (ball.size / 2.0)
		time_to_start -= delta
		# Flash border
		var time_msec = Time.get_ticks_msec()
		if sin(time_msec / 100.0) > 0:
			boundary.border_color = Color(1, 0, 0, 1)
		else:
			boundary.border_color = Color(0.3, 0, 0, 1)
			
		if time_to_start <= 0:
			prompt_label.visible = false
			boundary.border_color = Color(0.3, 0, 0, 1)
			
			if AudioManager:
				AudioManager.play_strike()
			
			var random_angle = randf() * TAU
			velocity = Vector2.from_angle(random_angle) * 50.0
			is_active = true
			has_started = true
	# 3. Update Visuals
	center = boundary.size / 2.0
	ball.position = center + position_offset - (ball.size / 2.0)
	
	var target_area = get_node_or_null("ReferenceRect/TargetArea")
	if target_area:
		target_area.custom_minimum_size = Vector2(TARGET_RADIUS * 2, TARGET_RADIUS * 2)
		target_area.size = Vector2(TARGET_RADIUS * 2, TARGET_RADIUS * 2)
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
	# Input (Counter-force)
	var input = Input.get_vector("left", "right", "up", "down")
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
			if balance_time >= 2.0:
				is_active = false
				velocity = Vector2.ZERO
				position_offset = Vector2.ZERO
				prompt_label.visible = false
				boundary.border_color = Color(0, 1, 0, 1) # Green border
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
	strike()
	has_started = false
	# Reset or keep failing? For now, reset to center to give a chance to recover
	position_offset = Vector2.ZERO
	velocity = Vector2.ZERO
