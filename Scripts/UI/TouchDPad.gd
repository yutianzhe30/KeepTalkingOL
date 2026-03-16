extends CanvasLayer

## 全局触控十字摇杆
## 将 UI 按钮按下/松开事件映射为全局 Input 动作
## 这样所有模块（包括平衡仪和迷宫）均可无缝使用

const BTN_SIZE  := Vector2(50, 50)
const BTN_ALPHA := 0.65
const MARGIN    := Vector2(12, 12)


func _ready() -> void:
	layer = 5
	name  = "TouchDPad"

	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	anchor.offset_left   = -(BTN_SIZE.x * 3 + MARGIN.x)
	anchor.offset_top    = -(BTN_SIZE.y * 3 + MARGIN.y)
	anchor.offset_right  = -MARGIN.x
	anchor.offset_bottom = -MARGIN.y
	add_child(anchor)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(grid)

	grid.add_child(_spacer())
	grid.add_child(_btn("↑", "up"))
	grid.add_child(_spacer())
	grid.add_child(_btn("←", "left"))
	grid.add_child(_spacer())
	grid.add_child(_btn("→", "right"))
	grid.add_child(_spacer())
	grid.add_child(_btn("↓", "down"))
	grid.add_child(_spacer())


func _spacer() -> Control:
	var s := Control.new()
	s.custom_minimum_size = BTN_SIZE
	return s


func _btn(label: String, action: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = BTN_SIZE
	btn.modulate = Color(1, 1, 1, BTN_ALPHA)

	btn.button_down.connect(func() -> void:
		var ev = InputEventAction.new()
		ev.action = action
		ev.pressed = true
		Input.parse_input_event(ev)
	)

	btn.button_up.connect(func() -> void:
		var ev = InputEventAction.new()
		ev.action = action
		ev.pressed = false
		Input.parse_input_event(ev)
	)

	# Fallback in case the user slides off the button
	btn.mouse_exited.connect(func() -> void:
		var ev = InputEventAction.new()
		ev.action = action
		ev.pressed = false
		Input.parse_input_event(ev)
	)

	return btn
