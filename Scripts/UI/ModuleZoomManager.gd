extends Node

signal zoomed_in(module: BaseModule)
signal zoomed_out

var _zoom_layer: CanvasLayer
var _backdrop: ColorRect
var _active_module: BaseModule = null
var _original_parent: Node = null
var _original_index: int = 0
var _registered_modules: Array[BaseModule] = []
var _placeholder: Control = null


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

	get_tree().root.add_child(_zoom_layer)
	_zoom_layer.hide()


func register(module: BaseModule) -> void:
	if not _registered_modules.has(module):
		_registered_modules.append(module)


func zoom_to(module: BaseModule) -> void:
	if _active_module == module:
		return
	if _active_module != null:
		_restore_module()

	_active_module = module
	_original_parent = module.get_parent()
	_original_index = module.get_index()

	# Insert placeholder to hold the grid slot while the module is reparented
	_placeholder = Control.new()
	_placeholder.custom_minimum_size = module.size
	_placeholder.size_flags_horizontal = module.size_flags_horizontal
	_placeholder.size_flags_vertical = module.size_flags_vertical
	_original_parent.add_child(_placeholder)
	_original_parent.move_child(_placeholder, _original_index)

	module.reparent(_zoom_layer)
	module.anchor_left   = 0.05
	module.anchor_right  = 0.95
	module.anchor_top    = 0.05
	module.anchor_bottom = 0.95
	module.offset_left   = 0
	module.offset_right  = 0
	module.offset_top    = 0
	module.offset_bottom = 0
	module.set_tappable(false)

	BaseModule.zoom_active = true
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
	if _placeholder != null:
		_placeholder.queue_free()
		_placeholder = null
	BaseModule.zoom_active = false
	m.on_zoom_restored()
	_zoom_layer.hide()


func _on_backdrop_input(event: InputEvent) -> void:
	var is_tap := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if is_tap:
		zoom_out()
