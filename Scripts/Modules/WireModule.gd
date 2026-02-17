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

func setup_rules():
	# SIMPLE LOGIC FOR PROTOTYPE:
	# Always cut the LAST wire.
	# TODO: Implement complex rules based on serial number, etc.
	solution_index = wires.size() - 1
	print("DEBUG: Cut wire index ", solution_index)

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
