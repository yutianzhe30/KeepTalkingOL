extends Control
class_name TutorialHint

# TutorialHint.gd
# 全屏半透明教程覆盖层。
# - 展开：显示 PanelContainer（遮住炸弹），右下角 FloatButton 隐藏
# - 收起：隐藏 PanelContainer，右下角显示 FloatButton，玩家可正常操作炸弹
# - hint_updated 信号触发时自动展开

@onready var hint_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HintLabel
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderRow/TitleLabel
@onready var panel: PanelContainer = $PanelContainer
@onready var float_button: Button = $FloatButton
@onready var dismiss_area: Button = $DismissArea

func _ready() -> void:
	GameState.hint_updated.connect(_on_hint_updated)
	_on_hint_updated(_get_welcome_hint())

func _on_hint_updated(hint_text: String) -> void:
	# 从首行 [b]...[/b] 提取标题显示到 header，正文去掉首行
	var lines := hint_text.split("\n", false, 2)
	if lines.size() >= 1:
		var raw_title := lines[0].strip_edges()
		title_label.text = raw_title.trim_prefix("[b]").trim_suffix("[/b]")
		var body := hint_text.substr(hint_text.find("\n") + 1).strip_edges()
		hint_label.parse_bbcode(body)
	else:
		title_label.text = "提示"
		hint_label.parse_bbcode(hint_text)
	_set_expanded(true) # 新提示出现时强制展开

func _on_toggle_pressed() -> void:
	_set_expanded(false)

func _on_float_pressed() -> void:
	_set_expanded(true)

func _set_expanded(expanded: bool) -> void:
	panel.visible = expanded
	dismiss_area.visible = expanded
	float_button.visible = not expanded

# ------------------------------------------------------------------
# 提示内容
# ------------------------------------------------------------------

static func _get_welcome_hint() -> String:
	return """[b]新手教程[/b]

你应该让你的同伴点击 [b]"我是拆弹专家"[/b] 来获得拆弹说明书。

这是一份危险的工作，多数情况下，你都应该在拆弹专家的指导下完成工作。

但在教程模式中，我会为你提供帮助。

[color=gray]——[/color]

接下来，请先点击 [b]接线模块[/b]，再解决 [b]按钮模块[/b]。"""

static func get_wire_hint() -> String:
	return """[b]接线模块[/b]

炸弹上有 [b]4 根[/b] 电线（红、蓝、黄、白）。

[b]4 根电线规则（按顺序判断）：[/b]
1. 红线多于 1 根，且序列号末位是奇数 → 剪最后一根红线
2. 最后一根是黄线，且没有红线 → 剪第一根
3. 恰好 1 根蓝线 → 剪第一根
4. 黄线多于 1 根 → 剪最后一根
5. 否则 → 剪第二根

[color=yellow]本关答案：[/color]
末位 4（偶数）→ 规则1不满足；最后是白线 → 规则2不满足
蓝线恰好 1 根 → [b]规则3：剪第 1 根（红色）[/b]

解决后请进行 [b]符号键盘模块[/b]"""

static func get_button_hint() -> String:
	return """[b]符号键盘模块[/b]

[b]解题步骤：[/b]
1. 查看 4 个按钮上的符号
2. 找到唯一包含这 4 个符号的列
3. 按该列从上到下的顺序依次点击

[color=yellow]本关答案：[/color]
4 个符号均来自列 1，点击顺序：Ϙ → Ѧ → ƛ → Ѣ

点错后模块重置，需重新开始。"""

static func get_complete_hint() -> String:
	return """[b]教程完成[/b]

你已成功解除了所有模块。
在实战中，你会遇到很多没见过的模块，请咨询你的拆弹专家
[color=green]总结：[/color]
· 序列号影响接线规则
· 符号键盘需找唯一包含所有符号的列

返回主菜单，点击 [b]开始游戏[/b] 可进入完整模式。"""
