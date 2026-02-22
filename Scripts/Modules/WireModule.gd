extends "res://Scripts/Modules/BaseModule.gd"

const WireScene = preload("res://Scenes/Modules/Wire.tscn")

@onready var container = $VBoxContainer

var wires = []
var solution_index: int = -1

func _ready():
	# Generate a random puzzle on start
	generate_puzzle(randi_range(3, 6))

func generate_puzzle(wire_count: int):
	# Clear existing
	for child in container.get_children():
		child.queue_free()
	wires.clear()
	
	# Create new wires
	for i in range(wire_count):
		var wire = WireScene.instantiate()
		container.add_child(wire)
		wire.wire_cut.connect(_on_wire_cut)
		
		# Random color
		var color = get_random_color()
		wire.setup(color)
		wires.append(wire)
	
	setup_rules()

func get_random_color() -> Color:
	var colors = [
		GlobalColors.COLOR_RED,
		GlobalColors.COLOR_BLUE,
		GlobalColors.COLOR_YELLOW,
		GlobalColors.COLOR_GREEN,
		GlobalColors.COLOR_WHITE,
		GlobalColors.COLOR_BLACK
	]
	return colors.pick_random()

func get_serial_number() -> String:
	# Attempt to find the SerialNumberModule in the tree to read its value.
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.has_method("get_debug_info"):
				var debug_info = child.get_debug_info()
				if debug_info.begins_with("Serial Number: "):
					return debug_info.replace("Serial Number: ", "").strip_edges()
	return "000000" # Fallback if no serial number module exists

func is_last_digit_odd(serial: String) -> bool:
	if serial.length() == 0: return false
	var last_char = serial[serial.length() - 1]
	if last_char.is_valid_int():
		return last_char.to_int() % 2 != 0
	return false

func setup_rules():
	var serial = get_serial_number()
	var last_digit_odd = is_last_digit_odd(serial)
	
	var count_red = 0
	var count_blue = 0
	var count_yellow = 0
	var count_white = 0
	var count_black = 0
	var last_red_index = -1
	
	for i in range(wires.size()):
		var color = wires[i].wire_color # Fixed accessing wire_color property on Wire.gd
		if color == GlobalColors.COLOR_RED:
			count_red += 1
			last_red_index = i
		elif color == GlobalColors.COLOR_BLUE: count_blue += 1
		elif color == GlobalColors.COLOR_YELLOW: count_yellow += 1
		elif color == GlobalColors.COLOR_WHITE: count_white += 1
		elif color == GlobalColors.COLOR_BLACK: count_black += 1

	var w_count = wires.size()
	
	if w_count == 3:
		if count_red == 0:
			solution_index = 1 # Second wire
		elif wires.back().color == GlobalColors.COLOR_WHITE:
			solution_index = 2 # Last wire
		elif count_blue > 1:
			solution_index = _get_last_wire_of_color(GlobalColors.COLOR_BLUE)
		else:
			solution_index = 2 # Last wire
	elif w_count == 4:
		if count_red > 1 and last_digit_odd:
			solution_index = last_red_index
		elif wires.back().color == GlobalColors.COLOR_YELLOW and count_red == 0:
			solution_index = 0 # First wire
		elif count_blue == 1:
			solution_index = 0 # First wire
		elif count_yellow > 1:
			solution_index = 3 # Last wire
		else:
			solution_index = 1 # Second wire
	elif w_count == 5:
		if wires.back().color == GlobalColors.COLOR_BLACK and last_digit_odd:
			solution_index = 3 # Fourth wire
		elif count_red == 1 and count_yellow > 1:
			solution_index = 0 # First wire
		elif count_black == 0:
			solution_index = 1 # Second wire
		else:
			solution_index = 0 # First wire
	elif w_count == 6:
		if count_yellow == 0 and last_digit_odd:
			solution_index = 2 # Third wire
		elif count_yellow == 1 and count_white > 1:
			solution_index = 3 # Fourth wire
		elif count_red == 0:
			solution_index = 5 # Last wire
		else:
			solution_index = 3 # Fourth wire

	print("DEBUG: Wire Module Rule Setup Complete. Expected index to cut: ", solution_index)

func _get_last_wire_of_color(target_color: Color) -> int:
	for i in range(wires.size() - 1, -1, -1):
		if wires[i].wire_color == target_color:
			return i
	return -1

func get_debug_info() -> String:
	var wire_colors = []
	for w in wires:
		# Convert color to name for debug
		var c = "Unknown"
		if w.wire_color == GlobalColors.COLOR_RED: c = "Red"
		elif w.wire_color == GlobalColors.COLOR_BLUE: c = "Blue"
		elif w.wire_color == GlobalColors.COLOR_YELLOW: c = "Yellow"
		elif w.wire_color == GlobalColors.COLOR_WHITE: c = "White"
		elif w.wire_color == GlobalColors.COLOR_BLACK: c = "Black"
		elif w.wire_color == GlobalColors.COLOR_GREEN: c = "Green"
		wire_colors.append(c)
		
	return "Wire Module: Puz=%s -> Cut wire index %d (1-indexed: %d)" % [str(wire_colors), solution_index, solution_index + 1]

func _on_wire_cut(wire_instance):
	var index = wires.find(wire_instance)
	
	if index == -1:
		return # Should not happen
		
	if index == solution_index:
		print("Correct wire cut!")
		solve()
	else:
		print("Wrong wire! Strike!")
		strike()
