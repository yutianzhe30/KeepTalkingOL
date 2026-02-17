extends Node

@export var strike_penalty_seconds: float = 30.0
@export var modules_root_path: NodePath = NodePath("../PanelContainer/MarginContainer/GridContainer")
@export var timer_module_path: NodePath = NodePath("../PanelContainer/MarginContainer/GridContainer/TimerModule")

var _timer_module: Node

func _ready() -> void:
	var modules_root = get_node_or_null(modules_root_path)
	_timer_module = get_node_or_null(timer_module_path)

	if modules_root == null:
		push_warning("BombManager: modules_root_path is invalid")
		return

	for child in modules_root.get_children():
		if child is BaseModule:
			var module := child as BaseModule
			module.module_struck.connect(_on_module_struck.bind(module))
			module.module_solved.connect(_on_module_solved.bind(module))

func _on_module_struck(module: BaseModule) -> void:
	print("BombManager strike from: ", module.name)
	if module == _timer_module:
		return
	if _timer_module != null:
		if _timer_module.has_method("add_time_penalty"):
			_timer_module.add_time_penalty(strike_penalty_seconds)
		if _timer_module.has_method("add_strike"):
			_timer_module.add_strike()

func _on_module_solved(module: BaseModule) -> void:
	print("BombManager solved: ", module.name)
