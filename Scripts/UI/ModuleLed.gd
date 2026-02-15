class_name ModuleLed
extends ColorRect

const DEFAULT_COLOR := Color(0.12, 0.12, 0.12, 1.0)
const SOLVED_COLOR := Color(0.1, 0.9, 0.2, 1.0)
const FAILED_COLOR := Color(1.0, 0.1, 0.1, 1.0)

@export var led_size: float = 10.0
@export var margin: float = 4.0
@export var flash_count: int = 3
@export var flash_on_time: float = 0.12
@export var flash_off_time: float = 0.08

var _flash_tween: Tween

func _ready() -> void:
	set_as_top_level(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	_apply_size()
	show_idle()

func show_idle() -> void:
	_kill_flash_tween()
	color = DEFAULT_COLOR

func show_solved() -> void:
	_kill_flash_tween()
	color = SOLVED_COLOR

func flash_failed(times: int = flash_count) -> void:
	_kill_flash_tween()
	_flash_tween = create_tween()
	for _i in range(times):
		_flash_tween.tween_property(self, "color", FAILED_COLOR, flash_on_time)
		_flash_tween.tween_property(self, "color", DEFAULT_COLOR, flash_off_time)

func place_top_right(module_rect: Rect2) -> void:
	global_position = module_rect.position + Vector2(module_rect.size.x - margin - led_size, margin)

func _apply_size() -> void:
	var indicator_size := Vector2(led_size, led_size)
	custom_minimum_size = indicator_size
	size = indicator_size

func _kill_flash_tween() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null
