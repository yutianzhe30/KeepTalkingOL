extends CanvasLayer

## 全局触控十字摇杆
## BombManager 负责将 dpad_pressed 信号连接到对应模块的方法上，
## 无需 InputMap 注册，也不干扰其他模块的轮询输入。

signal dpad_pressed(direction: int)
## direction: 0=上, 1=右, 2=下, 3=左

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
	grid.add_child(_btn("↑", 0))
	grid.add_child(_spacer())
	grid.add_child(_btn("←", 3))
	grid.add_child(_spacer())
	grid.add_child(_btn("→", 1))
	grid.add_child(_spacer())
	grid.add_child(_btn("↓", 2))
	grid.add_child(_spacer())


func _spacer() -> Control:
	var s := Control.new()
	s.custom_minimum_size = BTN_SIZE
	return s


func _btn(label: String, dir: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = BTN_SIZE
	btn.modulate = Color(1, 1, 1, BTN_ALPHA)
	btn.button_down.connect(func() -> void: dpad_pressed.emit(dir))
	return btn
