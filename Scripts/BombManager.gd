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

const RESULT_SCREEN_SCENE = preload("res://Scenes/UI/ResultScreen.tscn")
const TUTORIAL_HINT_SCENE = preload("res://Scenes/UI/TutorialHint.tscn")


var _timer_module: Node
var total_solvable: int = 0
var current_solved: int = 0
var game_ended: bool = false
var debug_info: String = ""
var _hint_modules_solved: int = 0 # Tracks how many solvable modules done (tutorial only)
var _hint_layer: CanvasLayer = null # Reference to tutorial hint layer so we can close it on exit


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
	
	_set_serial(modules_root)

	print("BombManager: Registered ", total_solvable, " solvable modules.")

	# Tutorial mode: spawn hint panel and emit the initial welcome hint
	if GameState.simple_mode:
		_hint_layer = CanvasLayer.new()
		_hint_layer.layer = 90
		var hint_instance = TUTORIAL_HINT_SCENE.instantiate()
		_hint_layer.add_child(hint_instance)
		get_tree().root.add_child(_hint_layer)
		# The hint panel's _ready() already emits the welcome hint, so just emit wire hint now
		# after a brief delay so the welcome text is visible first
		get_tree().create_timer(5.0).timeout.connect(
			func(): GameState.hint_updated.emit(TutorialHint.get_wire_hint())
		)

func _set_serial(modules_root: Node) -> void:
	# Inject serial number to all modules that need it
	var serial_string = "000000"
	var _serial_module: Node
	for child in modules_root.get_children():
		if child is SerialNumberModule:
			_serial_module = child
			break
			
	if _serial_module != null and _serial_module.has_method("get_serial_number"):
		serial_string = _serial_module.get_serial_number()
		
	for child in modules_root.get_children():
		if child.has_method("set_serial_number"):
			child.set_serial_number(serial_string)
			
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
	call_deferred("_get_all_debug_info")

func _get_all_debug_info() -> String:
	var debug_str = "========================================\n"
	debug_str += "BOMB DEBUG INFO (PUZZLES & SOLUTIONS)\n"
	debug_str += "========================================\n"
	var modules_root = get_node_or_null(modules_root_path)
	if modules_root:
		for child in modules_root.get_children():
			if child.has_method("get_debug_info"):
				debug_str += child.get_debug_info() + "\n"
	debug_str += "========================================"
	print(debug_str)
	debug_info = debug_str
	return debug_str

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

	# Tutorial hint progression
	if GameState.simple_mode:
		_advance_tutorial_hint()

	if current_solved >= total_solvable:
		_trigger_game_over(true)

func _advance_tutorial_hint() -> void:
	_hint_modules_solved += 1
	match _hint_modules_solved:
		1: # First module solved (Wire) -> show Button hint
			GameState.hint_updated.emit(TutorialHint.get_button_hint())
		2: # Second module solved (Button) -> show complete message
			GameState.hint_updated.emit(TutorialHint.get_complete_hint())

func _on_timer_exploded() -> void:
	if game_ended: return
	_trigger_game_over(false)

func _trigger_game_over(is_win: bool) -> void:
	game_ended = true
	# Close the tutorial hint panel when the game ends
	if _hint_layer != null:
		_hint_layer.queue_free()
		_hint_layer = null
	
	if _timer_module and _timer_module.has_method("stop_timer"):
		_timer_module.stop_timer()
		
	var time_str = "00:00"
	var strikes = 0
	if _timer_module:
		if _timer_module.get("label") != null:
			time_str = _timer_module.label.text
		if _timer_module.get("strike_count") != null:
			strikes = _timer_module.strike_count
			
	var result_scene = RESULT_SCREEN_SCENE.instantiate()
	var debug_str = debug_info
	result_scene.setup(is_win, time_str, strikes, debug_str)
	
	# Show result screen on the highest layer
	var canvaslayer = CanvasLayer.new()
	canvaslayer.layer = 100
	canvaslayer.add_child(result_scene)
	get_tree().root.add_child(canvaslayer)
