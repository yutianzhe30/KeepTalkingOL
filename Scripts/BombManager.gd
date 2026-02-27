extends Node

@export var strike_penalty_seconds: float = 30.0
@export var modules_root_path: NodePath = NodePath("../PanelContainer/MarginContainer/GridContainer")

@export var timer_scene: PackedScene
@export var wire_scene: PackedScene
@export var button_scene: PackedScene
@export var serial_scene: PackedScene
@export var ecg_scene: PackedScene
@export var balance_scene: PackedScene
@export var radio_scene: PackedScene
@export var press_scene: PackedScene
@export var placeholder_scene: PackedScene

var _timer_module: Node
var total_solvable: int = 0
var current_solved: int = 0
var game_ended: bool = false

func _ready() -> void:
	var modules_root = get_node_or_null(modules_root_path)

	if modules_root == null:
		push_warning("BombManager: modules_root_path is invalid")
		return
		
	_generate_modules(modules_root)

	for child in modules_root.get_children():
		if child is BaseModule:
			var module := child as BaseModule
			
			if child.has_signal("timer_exploded"):
				_timer_module = child
			
			# Filter out modules that are not puzzles
			if module.is_solvable:
				total_solvable += 1
				
			module.module_struck.connect(_on_module_struck.bind(module))
			module.module_solved.connect(_on_module_solved.bind(module))
		elif child.has_method("get_debug_info"):
			# For modules that might not inherit BaseModule but still have the method
			pass

	if _timer_module != null:
		if _timer_module.has_signal("timer_exploded"):
			_timer_module.timer_exploded.connect(_on_timer_exploded)

		# Inject timer reference to all modules that need it
		for child in modules_root.get_children():
			if child.has_method("set_timer_reference"):
				child.set_timer_reference(_timer_module)

	print("BombManager: Registered ", total_solvable, " solvable modules.")

func _generate_modules(root: Node) -> void:
	var sequence: Array[PackedScene] = [
		wire_scene,
		balance_scene,
		ecg_scene,
		button_scene,
		timer_scene,
		press_scene,
		radio_scene,
		serial_scene,
		placeholder_scene
	]
	
	if GameState.simple_mode:
		for i in range(sequence.size()):
			if sequence[i] not in [wire_scene, timer_scene, button_scene, serial_scene]:
				sequence[i] = placeholder_scene
			
	for scene in sequence:
		if scene:
			var instance = scene.instantiate()
			instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
			root.add_child(instance)

	# Print all debug information
	call_deferred("_print_all_debug_info")

func _print_all_debug_info() -> void:
	print("========================================")
	print("BOMB DEBUG INFO (PUZZLES & SOLUTIONS)")
	print("========================================")
	var modules_root = get_node_or_null(modules_root_path)
	if modules_root:
		for child in modules_root.get_children():
			if child.has_method("get_debug_info"):
				print(child.get_debug_info())
	print("========================================")

func _on_module_struck(module: BaseModule) -> void:
	if game_ended: return
	print("BombManager strike from: ", module.name)
	
	if AudioManager:
		AudioManager.play_strike()
		
	if module == _timer_module:
		return
	if _timer_module != null:
		if _timer_module.has_method("add_time_penalty"):
			_timer_module.add_time_penalty(strike_penalty_seconds)
		if _timer_module.has_method("add_strike"):
			_timer_module.add_strike()

func _on_module_solved(module: BaseModule) -> void:
	if game_ended: return
	if not module.is_solvable: return
	
	if AudioManager:
		AudioManager.play_solve()
		
	current_solved += 1
	print("BombManager solved: ", module.name, " (", current_solved, "/", total_solvable, ")")
	
	if current_solved >= total_solvable:
		_trigger_game_over(true)

func _on_timer_exploded() -> void:
	if game_ended: return
	_trigger_game_over(false)

func _trigger_game_over(is_win: bool) -> void:
	game_ended = true
	
	if _timer_module and _timer_module.has_method("stop_timer"):
		_timer_module.stop_timer()
		
	var time_str = "00:00"
	var strikes = 0
	if _timer_module:
		if _timer_module.get("label") != null:
			time_str = _timer_module.label.text
		if _timer_module.get("strike_count") != null:
			strikes = _timer_module.strike_count
			
	var result_scene = load("res://Scenes/UI/ResultScreen.tscn").instantiate()
	result_scene.setup(is_win, time_str, strikes)
	
	# Show result screen on the highest layer
	var canvaslayer = CanvasLayer.new()
	canvaslayer.layer = 100
	canvaslayer.add_child(result_scene)
	get_tree().root.add_child(canvaslayer)
