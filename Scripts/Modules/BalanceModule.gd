extends "res://Scripts/Modules/BaseModule.gd"

@onready var ball = $ReferenceRect/Ball
@onready var boundary = $ReferenceRect

func _init() -> void:
	is_solvable = false

var velocity: Vector2 = Vector2.ZERO
var position_offset: Vector2 = Vector2.ZERO # Position relative to center
var is_active: bool = true
var has_started: bool = false

# Physics Constants
const REPULSION_FORCE: float = 100.0 # Pushes ball away from center
const INPUT_FORCE: float = 300.0 # Player control strength
const DRAG: float = 1.0 # Air resistance
const RADIUS: float = 10.0 # Ball radius (half size)
const MAX_SPEED: float = 150.0 # Cap speed to give user a chance

func _ready():
	# Wait 1 second before starting the chaos
	await get_tree().create_timer(5).timeout
	if AudioManager:
		AudioManager.play_strike()
	# Give a random initial nudge
	var random_angle = randf() * TAU
	velocity = Vector2.from_angle(random_angle) * 50.0
	has_started = true

func _process(delta):
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
	
	# 3. Update Visuals
	# Center of boundary is size/2. Ball needs to be centered there.
	var center = boundary.size / 2.0
	ball.position = center + position_offset - (ball.size / 2.0)
	
	# 4. Check Collision (Fail Condition)
	check_boundary()
	
	# 5. Check Balanced (Win Condition)
	if has_started and state != ModuleState.SOLVED:
		# Check if ball is near center and nearly stopped
		if position_offset.length() < 15.0 and velocity.length() < 10.0:
			print("Balance Module Balanced! Solving.")
			is_active = false
			solve()

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
	# Reset or keep failing? For now, reset to center to give a chance to recover
	position_offset = Vector2.ZERO
	velocity = Vector2.ZERO
