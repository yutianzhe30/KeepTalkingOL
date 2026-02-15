class_name BaseModule
extends Control

signal module_solved
signal module_struck
signal state_changed(new_state: int)

enum ModuleState {
	IDLE,
	ACTIVE,
	SOLVED,
	FAILED,
}

const MODULE_LED_SCENE = preload("res://Scenes/UI/ModuleLed.tscn")

var state: ModuleState = ModuleState.IDLE
var _module_led: ModuleLed

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_POST_ENTER_TREE:
			_ensure_module_led()
			if state == ModuleState.IDLE:
				_set_state(ModuleState.ACTIVE)
			_update_led_for_state()
			_update_led_position()
		NOTIFICATION_RESIZED, NOTIFICATION_TRANSFORM_CHANGED:
			_update_led_position()

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
