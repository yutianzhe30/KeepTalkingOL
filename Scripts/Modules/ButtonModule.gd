extends "res://Scripts/Modules/BaseModule.gd"

# Button Module (Keypad Style)
# The user sees 4 buttons with symbols.
# They must press them in a specific order defined by which "List" the symbols belong to.

@onready var grid_container = $VBoxContainer/GridContainer
var buttons: Array[Button] = []

# Symbol Lists (Based on Keep Talking and Nobody Explodes Keypad)
# Using some Unicode characters as requested in AGENTS.md
const LISTS = [
	["Ϙ", "Ѧ", "ƛ", "Ѣ", "Ѭ", "ϗ", "Ͽ", ], # List 1
	["Ӭ", "Ϙ", "Ͽ", "Ҩ", "☆", "ϗ", "¿"], # List 2
	["©", "Ͼ", "Ҩ", "Ж", "ƛ", "Λ", "☆"], # List 3
	["б", "¶", "Ѣ", "Ѭ", "Ж", "¿", "Δ"], # List 4
	["Ψ", "Δ", "Ѣ", "Ͼ", "¶", "Ѯ", "★"], # List 5
	["б", "Ӭ", "҂", "æ", "Ψ", "Ҋ", "Ω"] # List 6
]

# State
var active_symbols: Array[String] = []
var correct_sequence: Array[int] = [] # Indices of buttons in order of pressing
var current_step: int = 0
var button_configs: Array[Dictionary] = [] # Stores {index: int, symbol: String} for each button

# Visual Configuration
const BUTTON_MIN_SIZE = Vector2(85, 100)
const BUTTON_FONT_SIZE = 40

const BUTTON_FONT = preload("res://Assets/Font/DejaVuSans.ttf")

func _ready():
	_setup_buttons()
	start_game()

func _setup_buttons():
	# Get existing button nodes from the scene
	for child in grid_container.get_children():
		if child is Button:
			buttons.append(child)
			child.custom_minimum_size = BUTTON_MIN_SIZE
			child.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
			if BUTTON_FONT:
				child.add_theme_font_override("font", BUTTON_FONT)
			child.pressed.connect(_on_button_pressed.bind(buttons.size() - 1))

func start_game():
	current_step = 0
	if GameState.simple_mode:
		_pick_fixed_puzzle()
	else:
		_pick_puzzle()
	_update_button_visuals()

func _pick_puzzle():
	# 1. Pick a random list
	var chosen_list = LISTS.pick_random()
	
	# 2. Pick 4 unique symbols from that list
	# We need to preserve their relative order from the original list for the solution
	var available_indices = []
	for i in range(chosen_list.size()):
		available_indices.append(i)
	
	available_indices.shuffle()
	var chosen_indices = available_indices.slice(0, 4)
	chosen_indices.sort() # Sort indices to get correct solution order
	
	active_symbols.clear()
	correct_sequence.clear()
	button_configs.clear()
	
	# Create the solution
	var temp_symbols = []
	for idx in chosen_indices:
		temp_symbols.append(chosen_list[idx])
	
	print("Button Module Debug: Correct Order -> ", temp_symbols)

	# Map these symbols to random buttons
	var button_indices = [0, 1, 2, 3]
	button_indices.shuffle()
	
	# Assign symbols to buttons
	var symbol_to_button_map = {}
	
	for i in range(4):
		var btn_idx = button_indices[i]
		var symbol = temp_symbols[i] # temp_symbols is the correct chronological order
		
		button_configs.append({
			"button_index": btn_idx,
			"symbol": symbol
		})
		
		symbol_to_button_map[symbol] = btn_idx
		
	for sym in temp_symbols:
		correct_sequence.append(symbol_to_button_map[sym])

# Tutorial mode: fixed symbols from List 1 in display order 0-1-2-3
func _pick_fixed_puzzle() -> void:
	active_symbols.clear()
	correct_sequence.clear()
	button_configs.clear()

	# Use first 4 symbols of List 1: Ϙ Ѧ ƛ Ѣ
	var fixed_symbols: Array[String] = ["Ϙ", "Ѧ", "ƛ", "Ѣ"]
	for i in range(4):
		button_configs.append({"button_index": i, "symbol": fixed_symbols[i]})
		active_symbols.append(fixed_symbols[i])

	# Correct press order: 0 -> 1 -> 2 -> 3  (left-to-right, top-to-bottom)
	correct_sequence = [0, 1, 2, 3]
	print("ButtonModule [Tutorial]: Fixed puzzle loaded. Press order: ", correct_sequence)

func get_debug_info() -> String:
	var sequence_symbols = []
	for idx in correct_sequence:
		var btn = buttons[idx]
		sequence_symbols.append(btn.text)
	return "Button Sequence: press " + str(sequence_symbols)

func _update_button_visuals():
	for config in button_configs:
		var btn = buttons[config.button_index]
		btn.text = config.symbol
		# Reset state
		btn.disabled = false
		btn.modulate = Color(1, 1, 1, 1) # White

func _on_button_pressed(btn_index: int):
	if state == ModuleState.SOLVED:
		return
		
	if btn_index == correct_sequence[current_step]:
		print("Button Module: Correct press ", current_step + 1, "/", 4)

		# Visual Logic: Show clicked (Green + Disabled)
		# We need to find the button object that corresponds to this index
		# Since 'buttons' array is indexed by 'btn_index', we can use it directly.
		var btn = buttons[btn_index]
		btn.modulate = Color(0, 1, 0, 1) # Green
		btn.disabled = true
		
		current_step += 1
		
		if current_step >= 4:
			solve()
	else:
		print("Button Module: Wrong press! Expected button ", correct_sequence[current_step], " but got ", btn_index)
		strike()
		current_step = 0 # Reset progress on strike
		
		# Visual Logic: Reset all buttons
		_update_button_visuals()
