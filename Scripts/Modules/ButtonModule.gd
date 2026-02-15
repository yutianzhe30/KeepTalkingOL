extends "res://Scripts/Modules/BaseModule.gd"

# Button Module (Keypad Style)
# The user sees 4 buttons with symbols.
# They must press them in a specific order defined by which "List" the symbols belong to.

@onready var grid_container = $VBoxContainer/GridContainer
var buttons: Array[Button] = []

# Symbol Lists (Based on Keep Talking and Nobody Explodes Keypad)
# Using some Unicode characters as requested in AGENTS.md
const LISTS = [
	["Ϙ", "Ѧ", "ƛ", "Ϟ", "Ѭ", "ϗ", "Ͽ", ], # List 1
	["Ӭ", "Ϙ", "Ͽ", "Ҩ", "☆", "ϗ", "¿"], # List 2
	["©", "Ѽ", "Ҩ", "Ж", "ƛ", "ㄓ", "☆"], # List 3
	["б", "¶", "Ѣ", "Ѭ", "Ж", "¿", "ツ"], # List 4
	["Ψ", "ツ", "Ѣ", "Ͼ", "¶", "Ѯ", "★"], # List 5
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
			child.pressed.connect(_on_button_pressed.bind(buttons.size() - 1))

func start_game():
	current_step = 0
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
	#button_indices.shuffle()
	
	# Assign symbols to buttons
	# temp_symbols is in correct order.
	# We need to know which BUTTON corresponds to which step in the sequence.
	
	# Example:
	# Solution: [A, B, C, d]
	# Buttons (randomized): [2:A, 0:B, 3:C, 1:d]
	# Correct Sequence (Button Indices): [2, 0, 3, 1]
	
	# Let's verify the logic:
	# chosen_list = [A, B, C, D, E, F]
	# chosen_indices = [0, 1, 3, 5] -> [A, B, D, F] (Correct Order)
	
	# We have 4 buttons.
	# We assign the 4 symbols to the 4 buttons randomly.
	
	var symbol_to_button_map = {}
	
	for i in range(4):
		var btn_idx = button_indices[i]
		var symbol = temp_symbols[i] # This is the i-th symbol in the CORRECT sequence
		
		# Wait, shuffling button_indices implies:
		# i=0 (First in seq) -> goes to button `button_indices[0]`
		# i=1 (Second in seq) -> goes to button `button_indices[1]`
		
		# So `correct_sequence` should simply be `button_indices`!
		# Because button_indices[0] HAS the first symbol.
		# button_indices[1] HAS the second symbol.
		
		button_configs.append({
			"button_index": btn_idx,
			"symbol": symbol
		})
		
		symbol_to_button_map[symbol] = btn_idx
		
	# Re-construct correct_sequence based on the sorted symbols
	for sym in temp_symbols:
		correct_sequence.append(symbol_to_button_map[sym])

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
