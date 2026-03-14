extends "res://Scripts/Modules/BaseModule.gd"

# Press The Button Module
# A big circular button.
# Rules:
# 1. Action: Tap or Hold?
# 2. If Hold: Release when timer has specific digit.

@onready var main_button = $CenterContainer/MainButton
@onready var strip_color_rect = $StripColor

# Config
const COLORS = {
	"Red": GlobalColors.COLOR_RED,
	"Blue": GlobalColors.COLOR_BLUE,
	"Yellow": GlobalColors.COLOR_YELLOW,
	"White": GlobalColors.COLOR_WHITE
}

const TEXTS = ["PRESS", "HOLD", "ABORT", "DETONATE"]

# State
var button_color_name: String
var button_text: String
var required_action: String = "TAP" # "TAP" or "HOLD"
var strip_color_name: String
var release_digit: int = -1

var is_holding: bool = false
var hold_time: float = 0.0
var hold_threshold: float = 0.5 # Seconds to consider it a "hold"
var interaction_active: bool = false

# Timer Reference
var timer_module = null

func _ready():
	#super._ready()
	# Circular Style for Button
	var style_box = StyleBoxFlat.new()
	style_box.set_corner_radius_all(100) # Circle
	main_button.add_theme_stylebox_override("normal", style_box)
	main_button.add_theme_stylebox_override("hover", style_box)
	main_button.add_theme_stylebox_override("pressed", style_box)
	main_button.add_theme_stylebox_override("disabled", style_box)
	
	main_button.button_down.connect(_on_button_down)
	main_button.button_up.connect(_on_button_up)
	
	_setup_puzzle()

func set_timer_reference(ref):
	timer_module = ref

func _setup_puzzle():
	# Randomize Button
	button_color_name = COLORS.keys().pick_random()
	button_text = TEXTS.pick_random()
	
	# Visuals
	var style_box = main_button.get_theme_stylebox("normal")
	style_box.bg_color = COLORS[button_color_name]
	
	# Text Color (Black for visibility on light colors, White on dark?)
	if button_color_name in ["White", "Yellow"]:
		main_button.add_theme_color_override("font_color", Color.BLACK)
	else:
		main_button.add_theme_color_override("font_color", Color.WHITE)
		
	main_button.text = button_text
	
	# Determine Logic
	_determine_rules()

func _determine_rules():
	# Standard "Big Button" Rules (Simplified adaptation)
	# 1. If Blue and "Abort" -> Hold
	# 2. If text "Detonate" and Batteries > 1 (No batteries yet) -> Let's say: If Detonate -> Press
	# 3. If White and "Car" (No indicators) -> Let's say: If White -> Hold
	# 4. If Batteries > 2 and "Lit FRK" -> Press
	# 5. If Yellow -> Hold
	# 6. If Red and "Hold" -> Press
	# 7. Else -> Hold
	# Simplified Rules for now:
	if button_color_name == "Blue" and button_text == "ABORT":
		required_action = "HOLD"
	elif button_text == "DETONATE":
		required_action = "TAP" # Original: Check batteries. Short-circuit to Tap for now.
	elif button_color_name == "White":
		required_action = "HOLD"
	elif button_color_name == "Yellow":
		required_action = "HOLD"
	elif button_color_name == "Red" and button_text == "HOLD":
		required_action = "TAP"
	else:
		required_action = "HOLD"
		
	if required_action == "HOLD":
		_precalculate_hold_logic()

	print("PressModule: ", button_color_name, " ", button_text, " -> ", required_action)

func _precalculate_hold_logic():
	strip_color_name = COLORS.keys().pick_random()

	match strip_color_name:
		"Blue": release_digit = 4
		"Yellow": release_digit = 5
		_: release_digit = 1

func get_debug_info() -> String:
	if required_action == "TAP":
		return "Press Module: TAP the %s button." % button_text
	else:
		return "Press Module: HOLD the %s button. (Strip: %s, Release on: %d)" % [button_text, strip_color_name, release_digit]

func _start_hold_phase():
	# Show Strip Logic
	strip_color_rect.color = COLORS[strip_color_name]
	strip_color_rect.visible = true

func _process(delta):
	if state == ModuleState.SOLVED:
		return
		
	if interaction_active:
		hold_time += delta
		if hold_time > hold_threshold and not is_holding:
			is_holding = true
			# We are now in "Hold" territory
			_start_hold_phase()

func _on_button_down():
	if state == ModuleState.SOLVED:
		return
	
	interaction_active = true
	hold_time = 0.0
	is_holding = false
	
	_animate_button_press(true)

func _on_button_up():
	if state == ModuleState.SOLVED:
		return
		
	interaction_active = false
	strip_color_rect.visible = false
	
	_animate_button_press(false)
	
	if not is_holding:
		# It was a TAP
		if required_action == "TAP":

			solve()
		else:

			strike()
	else:
		# It was a HOLD release
		if required_action == "TAP":
			# If we held effectively (strip appeared) but rule was TAP

			strike()
			return
			
		# Rule was HOLD. Check Release Time.
		if not timer_module:

			return
			
		if _check_timer_digit(release_digit):

			solve()
		else:

			strike()

func _animate_button_press(is_pressed: bool):
	var tween = create_tween().set_parallel(true)
	var style = main_button.get_theme_stylebox("normal")
	var target_color = COLORS[button_color_name]
	var target_scale = Vector2(1.0, 1.0)
	
	if is_pressed:
		target_color = target_color.darkened(0.2)
		target_scale = Vector2(0.95, 0.95)
	
	tween.tween_property(style, "bg_color", target_color, 0.1)
	
	# Ensure pivot is center for scaling
	main_button.pivot_offset = main_button.size / 2
	tween.tween_property(main_button, "scale", target_scale, 0.1)

func _check_timer_digit(target_digit: int) -> bool:
	if not timer_module: return false
	
	# Access formatted text directly as it's what player sees
	var text = timer_module.label.text
	return text.contains(str(target_digit))
