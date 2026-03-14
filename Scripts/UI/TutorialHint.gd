extends Control
class_name TutorialHint

# TutorialHint.gd
# A floating panel that displays manual-based hints to guide tutorial players.
# Driven by GameState.hint_updated signal emitted by BombManager.

@onready var hint_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HintLabel
@onready var toggle_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ToggleButton
@onready var panel: PanelContainer = $PanelContainer

var _collapsed: bool = false

func _ready() -> void:
	GameState.hint_updated.connect(_on_hint_updated)
	# Note: toggle_button.pressed is already connected in the scene file (.tscn)
	# Show the welcome hint immediately
	_on_hint_updated(_get_welcome_hint())

func _on_hint_updated(hint_text: String) -> void:
	hint_label.text = hint_text

func _on_toggle_pressed() -> void:
	_collapsed = not _collapsed
	hint_label.visible = not _collapsed
	toggle_button.text = "展开 ▲" if _collapsed else "收起 ▼"

# ------------------------------------------------------------------
# Hint content strings (drawn from MANUAL_CN.md)
# ------------------------------------------------------------------

static func _get_welcome_hint() -> String:
	return """[b]💡 新手教程[/b]

[color=yellow]第一步：找到序列号模块[/color]
炸弹外壳上会贴有一张 [b]6 位序列号贴纸[/b]。
本教程固定序列号为：[b]A1B2C4[/b]
（最后一位 [b]4[/b] = 偶数，在解题中很重要）

接下来请解决 [b]接线模块[/b] ✂️"""

static func get_wire_hint() -> String:
	return """[b]✂️ 接线模块[/b]（手册第1节）

炸弹上有 [b]4 根[/b] 电线（红、蓝、黄、白）。

[b]4根电线规则（按顺序判断第一条匹配项）：[/b]
1. 红线 > 1 根 [b]且[/b] 序列号末位是奇数 → 剪[b]最后一根红线[/b]
2. 最后一根是黄线 [b]且[/b] 没有红线 → 剪[b]第一根[/b]
3. 恰好 1 根蓝线 → 剪[b]第一根[/b]
4. 黄线 > 1 根 → 剪[b]最后一根[/b]
5. 否则 → 剪[b]第二根[/b]

[color=yellow]本谜题提示：[/color]
序列号末位 = 4（偶数）
红线 = 1 根（不满足规则 1）
最后一根是白线（不满足规则 2）
→ 蓝线恰好 1 根 [b]→ 规则 3：剪第 1 根（红色）[/b]

接下来请解决 [b]符号键盘模块[/b] 🔘"""

static func get_button_hint() -> String:
	return """[b]🔘 符号键盘模块[/b]（手册第4节）

[b]解题步骤：[/b]
1. 查看所有 4 个符号
2. 找到[b]唯一[/b]包含这 4 个符号的列
3. 按照该列[b]从上到下[/b]的顺序依次点击

符号列表（列 1）：
  Ϙ → Ѧ → ƛ → Ѣ

[color=yellow]本谜题提示：[/color]
4 个符号均来自 [b]列 1[/b]
→ 按从左到右、从上到下的顺序点击：Ϙ → Ѧ → ƛ → Ѣ

注意：点错后模块会重置，需重新开始。"""

static func get_complete_hint() -> String:
	return """[b]🎉 恭喜你完成新手教程！[/b]

你已成功解除了所有模块。

[color=green]学到了什么？[/color]
• 序列号影响接线模块的解题规则
• 符号键盘需要找唯一包含所有符号的列

现在可以挑战[b]完整模式[/b]了！
返回主菜单点击"开始游戏"即可。"""
