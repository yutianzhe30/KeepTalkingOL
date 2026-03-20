class_name BaseModule
extends Control

@export var is_solvable: bool = true

signal module_solved
signal module_struck
signal module_tapped(module: BaseModule)
signal state_changed(new_state: int)

enum ModuleState {
	IDLE,
	ACTIVE,
	SOLVED,
	FAILED,
}

const MODULE_LED_SCENE = preload("res://Scenes/UI/ModuleLed.tscn")

static var zoom_active: bool = false  # true while any module is zoomed in

var state: ModuleState = ModuleState.IDLE
var is_zoomed: bool = false  # true when this specific module is the zoomed one
var _module_led: ModuleLed
var _tap_overlay: Control = null

func set_tappable(value: bool) -> void:
	if _tap_overlay != null:
		_tap_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE

func on_zoom_restored() -> void:
	pass  # Override in subclasses if needed

func _on_tap_overlay_input(event: InputEvent) -> void:
	if state == ModuleState.SOLVED or BaseModule.zoom_active:
		return
	var is_tap := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if is_tap:
		module_tapped.emit(self)
		_tap_overlay.accept_event()  # 吃掉事件，防止穿透到模块内部（如导线按钮）

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			_tap_overlay = Control.new()
			_tap_overlay.name = "TapOverlay"
			_tap_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			_tap_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
			_tap_overlay.z_index = 100
			_tap_overlay.gui_input.connect(_on_tap_overlay_input)
			add_child(_tap_overlay)
		NOTIFICATION_POST_ENTER_TREE:
			_ensure_module_led()
			if state == ModuleState.IDLE:
				_set_state(ModuleState.ACTIVE)
			_update_led_for_state()
			_update_led_position()
		NOTIFICATION_RESIZED, NOTIFICATION_TRANSFORM_CHANGED:
			_update_led_position()

# Virtual method for printing debug information about the puzzle and solution
func get_debug_info() -> String:
	return "No debug info available for this module."

# Backward-compatible wrappers for existing modules.
func solve() -> void:
	mark_solved()

func strike() -> void:
	mark_failed()

func mark_solved() -> void:
	if state == ModuleState.SOLVED:
		return

	_set_state(ModuleState.SOLVED)
	_update_led_for_state()

	print("Module Solved!")
	module_solved.emit()

func mark_failed() -> void:
	if state == ModuleState.SOLVED:
		return

	_set_state(ModuleState.FAILED)
	if _module_led != null:
		_module_led.flash_failed()

	print("Module Strike!")
	module_struck.emit()

func _ensure_module_led() -> void:
	if _module_led != null:
		return

	_module_led = get_node_or_null("ModuleLED") as ModuleLed
	if _module_led != null:
		return

	var led_instance = MODULE_LED_SCENE.instantiate()
	if led_instance is ModuleLed:
		_module_led = led_instance as ModuleLed
		_module_led.name = "ModuleLED"
		add_child(_module_led)

func _update_led_for_state() -> void:
	if _module_led == null:
		return

	if state == ModuleState.SOLVED:
		_module_led.show_solved()
	else:
		_module_led.show_idle()

func _update_led_position() -> void:
	if _module_led == null:
		return

	_module_led.place_top_right(get_global_rect())


func _set_state(new_state: ModuleState) -> void:
	if state == new_state:
		return

	state = new_state
	state_changed.emit(state)
