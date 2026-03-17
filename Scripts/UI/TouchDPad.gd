extends CanvasLayer

## 全局虚拟摇杆（圆形）
## - Input.action_press() 连续更新模拟强度（BalanceModule 用 Input.get_vector() 读取）
## - 阈值穿越时才用 parse_input_event() 发送离散事件（MazeRedDotsModule 用 is_action_pressed()）

const OUTER_RADIUS    := 68.0
const KNOB_RADIUS     := 28.0
const MARGIN          := Vector2(24, 24)
const PRESS_THRESHOLD := 0.30   # 超过此归一化距离才算"按下"


func _ready() -> void:
	layer = 5
	name  = "TouchDPad"

	var ctrl := _JoystickControl.new()
	var sz   := OUTER_RADIUS * 2.0 + 8.0
	ctrl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ctrl.offset_left   = -(sz + MARGIN.x)
	ctrl.offset_top    = -(sz + MARGIN.y)
	ctrl.offset_right  = -MARGIN.x
	ctrl.offset_bottom = -MARGIN.y
	ctrl.custom_minimum_size = Vector2(sz, sz)
	add_child(ctrl)


# ─────────────────────────────────────────────────────────────────────────────
class _JoystickControl extends Control:

	const OUTER_RADIUS    := 68.0
	const KNOB_RADIUS     := 28.0
	const PRESS_THRESHOLD := 0.30

	const COLOR_BG   := Color(0.12, 0.12, 0.12, 0.55)
	const COLOR_RING := Color(1.0,  1.0,  1.0,  0.60)
	const COLOR_KNOB := Color(0.80, 0.80, 0.80, 0.75)
	const COLOR_KNOB_EDGE := Color(1.0, 1.0, 1.0, 0.85)

	var _knob_offset := Vector2.ZERO
	var _touching    := false
	var _touch_id    := -1

	# 记录每个方向当前是否已"按下"（用于检测阈值穿越）
	var _was_pressed := { "up": false, "down": false, "left": false, "right": false }


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP


	func _draw() -> void:
		var c := size / 2.0

		# 外圆背景 + 边框
		draw_circle(c, OUTER_RADIUS, COLOR_BG)
		draw_arc(c, OUTER_RADIUS, 0.0, TAU, 64, COLOR_RING, 2.5)

		# 内部十字参考线（淡色）
		var arm := OUTER_RADIUS * 0.55
		draw_line(c + Vector2(0, -arm), c + Vector2(0, arm),  Color(1, 1, 1, 0.15), 1.5)
		draw_line(c + Vector2(-arm, 0), c + Vector2(arm, 0),  Color(1, 1, 1, 0.15), 1.5)

		# 摇杆圆钮
		var kp := c + _knob_offset
		draw_circle(kp, KNOB_RADIUS, COLOR_KNOB)
		draw_arc(kp, KNOB_RADIUS, 0.0, TAU, 32, COLOR_KNOB_EDGE, 2.0)


	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var te := event as InputEventScreenTouch
			if te.pressed and not _touching:
				var lp := _to_local(te.position)
				if Rect2(Vector2.ZERO, size).has_point(lp):
					_touching = true
					_touch_id = te.index
					_update_knob(lp)
					get_viewport().set_input_as_handled()
			elif not te.pressed and te.index == _touch_id:
				_touching = false
				_touch_id = -1
				_update_knob(null)
				get_viewport().set_input_as_handled()

		elif event is InputEventScreenDrag:
			var de := event as InputEventScreenDrag
			if _touching and de.index == _touch_id:
				_update_knob(_to_local(de.position))
				get_viewport().set_input_as_handled()

		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					var lp := get_local_mouse_position()
					if Rect2(Vector2.ZERO, size).has_point(lp):
						_touching = true
						_update_knob(lp)
				else:
					_touching = false
					_update_knob(null)

		elif event is InputEventMouseMotion and _touching:
			_update_knob(get_local_mouse_position())


	func _to_local(global_pos: Vector2) -> Vector2:
		return get_global_transform().affine_inverse() * global_pos


	func _update_knob(local_pos) -> void:
		if local_pos == null:
			_knob_offset = Vector2.ZERO
		else:
			var delta := (local_pos as Vector2) - size / 2.0
			if delta.length() > OUTER_RADIUS:
				delta = delta.normalized() * OUTER_RADIUS
			_knob_offset = delta

		var norm := _knob_offset / OUTER_RADIUS   # [-1, 1]

		_apply_axis("right", max(0.0,  norm.x))
		_apply_axis("left",  max(0.0, -norm.x))
		_apply_axis("down",  max(0.0,  norm.y))
		_apply_axis("up",    max(0.0, -norm.y))

		queue_redraw()


	## 更新单个方向轴：
	##   - Input.action_press/release 连续维护模拟强度（不触发 _unhandled_input）
	##   - 阈值穿越时额外发 parse_input_event，供离散模块（MazeRedDots）使用
	func _apply_axis(action: String, strength: float) -> void:
		var now_pressed := strength >= PRESS_THRESHOLD
		var was: bool   = _was_pressed[action]

		if strength > 0.0:
			Input.action_press(action, strength)
		else:
			Input.action_release(action)

		if now_pressed != was:
			var ev         := InputEventAction.new()
			ev.action      = action
			ev.pressed     = now_pressed
			ev.strength    = strength
			Input.parse_input_event(ev)
			_was_pressed[action] = now_pressed
