extends Node

signal zoomed_in(module: BaseModule)
signal zoomed_out

var _zoom_layer: CanvasLayer
var _backdrop: ColorRect
var _display: Control
var _active_module: BaseModule = null
var _original_parent: Node = null
var _original_index: int = 0


func _ready() -> void:
	_zoom_layer = CanvasLayer.new()
	_zoom_layer.layer = 50
	_zoom_layer.name = "ModuleZoomLayer"

	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0.6)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	_zoom_layer.add_child(_backdrop)

	_display = Control.new()
	_display.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zoom_layer.add_child(_display)

	get_tree().root.add_child(_zoom_layer)
	_zoom_layer.hide()


func zoom_to(module: BaseModule) -> void:
	if _active_module == module:
		return
	if _active_module != null:
		_restore_module()

	_active_module = module
	_original_parent = module.get_parent()
	_original_index = module.get_index()

	module.reparent(_display)
	module.set_anchors_preset(Control.PRESET_FULL_RECT)
	module.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	module.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_zoom_layer.show()
	zoomed_in.emit(module)


func zoom_out() -> void:
	if _active_module == null:
		return
	_restore_module()
	zoomed_out.emit()


func _restore_module() -> void:
	if _active_module == null:
		return
	var m := _active_module
	_active_module = null
	m.reparent(_original_parent)
	_original_parent.move_child(m, _original_index)
	m.set_anchors_preset(Control.PRESET_TOP_LEFT)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_zoom_layer.hide()


func _on_backdrop_input(event: InputEvent) -> void:
	var is_tap := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if is_tap:
		zoom_out()
