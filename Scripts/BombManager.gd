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
@export var maze_scene: PackedScene
@export var placeholder_scene: PackedScene

const RESULT_SCREEN_SCENE   = preload("res://Scenes/UI/ResultScreen.tscn")
const TUTORIAL_HINT_SCENE   = preload("res://Scenes/UI/TutorialHint.tscn")
const TOUCH_DPAD            = preload("res://Scripts/UI/TouchDPad.gd")
const MODULE_ZOOM_MANAGER   = preload("res://Scripts/UI/ModuleZoomManager.gd")


var _timer_module: Node
var total_solvable: int = 0
var current_solved: int = 0
var game_ended: bool = false
var debug_info: String = ""
var _hint_modules_solved: int = 0 # Tracks how many solvable modules done (tutorial only)
var _hint_layer: CanvasLayer = null # Reference to tutorial hint layer so we can close it on exit
var _dpad_layer: CanvasLayer = null # Reference to touch D-pad overlay
var _zoom_manager = null            # ModuleZoomManager (mobile only)


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

	# Mobile: zoom-on-tap + conditional D-pad (shown only when balance/maze is zoomed)
	# TODO: remove desktop from this condition after debugging
	if true or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		_zoom_manager = MODULE_ZOOM_MANAGER.new()
		add_child(_zoom_manager)

		var needs_dpad := false
		for child in modules_root.get_children():
			if child is MazeRedDotsModule or child is BalanceModule:
				needs_dpad = true
			# Connect tap-to-zoom for all modules except Timer and Serial
			if child is BaseModule and not (child is TimerModule) and not (child is SerialNumberModule):
				_zoom_manager.register(child)
				child.module_tapped.connect(_zoom_manager.zoom_to)
				child.module_solved.connect(_zoom_manager.zoom_out)

		_zoom_manager.zoomed_in.connect(_on_zoom_in)
		_zoom_manager.zoomed_out.connect(_on_zoom_out)

		if needs_dpad:
			_dpad_layer = TOUCH_DPAD.new()
			_dpad_layer.hide()
			get_tree().root.add_child(_dpad_layer)

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
			
const GRID_SIZE := 9
const GRID_COLS := 3

# Fixed positions in 3x3 grid (0-indexed):
#  0  1  2
#  3  4  5
#  6  7  8
enum GridPos {
	TOP_LEFT = 0, TOP_MID = 1, TOP_RIGHT = 2,
	MID_LEFT = 3, CENTER = 4, MID_RIGHT = 5,
	BOT_LEFT = 6, BOT_MID = 7, BOT_RIGHT = 8
}

## Generates all modules and places them in the grid.
## Fixed positions: Timer (center), Serial (bottom-right), Balance (top-right), Maze (bottom-middle in Hard)
func _generate_modules(root: Node) -> void:
	var sequence := _create_empty_sequence()
	
	# Step 1: Place fixed-position modules
	sequence[GridPos.CENTER] = timer_scene
	sequence[GridPos.BOT_RIGHT] = serial_scene
	
	# Step 2: Get puzzle modules for current difficulty
	var puzzle_modules := _get_puzzle_modules_for_difficulty()
	
	# Step 3: Place conditional fixed-position modules
	var occupied_slots := [GridPos.CENTER, GridPos.BOT_RIGHT]
	
	# Balance -> top-right (slot 2)
	if balance_scene in puzzle_modules:
		puzzle_modules.erase(balance_scene)
		sequence[GridPos.TOP_MID] = balance_scene
		occupied_slots.append(GridPos.TOP_MID)
	
	# Maze -> bottom-middle (slot 7) in Hard mode
	if GameState.difficulty == GameState.Difficulty.HARD:
		sequence[GridPos.BOT_MID] = maze_scene
		occupied_slots.append(GridPos.BOT_MID)
	
	# Step 4: Fill remaining slots randomly
	var available_slots := _get_available_slots(occupied_slots)
	available_slots.shuffle()
	
	for i in range(min(puzzle_modules.size(), available_slots.size())):
		sequence[available_slots[i]] = puzzle_modules[i]
	
	# Step 5: Instantiate all modules
	_instantiate_modules(sequence, root)
	
	call_deferred("_get_all_debug_info")


func _create_empty_sequence() -> Array:
	var sequence: Array = []
	sequence.resize(GRID_SIZE)
	sequence.fill(placeholder_scene)
	return sequence


func _get_puzzle_modules_for_difficulty() -> Array:
	if GameState.simple_mode:
		return [wire_scene, button_scene]
	
	var basic_pool: Array = [wire_scene, button_scene, press_scene, radio_scene, ecg_scene]
	basic_pool.shuffle()
	
	match GameState.difficulty:
		GameState.Difficulty.EASY:
			return [basic_pool[0], basic_pool[1]]
		GameState.Difficulty.MEDIUM:
			return [balance_scene] + basic_pool.slice(0, 4)
		GameState.Difficulty.HARD:
			return [balance_scene] + basic_pool
		_:
			return []


func _get_available_slots(occupied: Array) -> Array:
	var all_slots := range(GRID_SIZE)
	var available: Array = []
	for slot in all_slots:
		if slot not in occupied:
			available.append(slot)
	return available


func _instantiate_modules(sequence: Array, root: Node) -> void:
	for scene in sequence:
		if not scene:
			continue
		var instance = scene.instantiate()
		instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(instance)

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

func _on_zoom_in(module: BaseModule) -> void:
	if _dpad_layer != null and (module is BalanceModule or module is MazeRedDotsModule):
		_dpad_layer.show()

func _on_zoom_out() -> void:
	if _dpad_layer != null:
		_dpad_layer.hide()

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
	if _hint_layer != null:
		_hint_layer.queue_free()
		_hint_layer = null
	if _zoom_manager != null:
		_zoom_manager.zoom_out()
		_zoom_manager.queue_free()
		_zoom_manager = null
	if _dpad_layer != null:
		_dpad_layer.queue_free()
		_dpad_layer = null
	
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
