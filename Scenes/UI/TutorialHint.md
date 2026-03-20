## 教程 Overlay 设计规范

### 视觉设计
- 半透明深色背景（`Color(0.08, 0.08, 0.08, 0.88)`），遮住炸弹
- 不用 Emoji
- 占据全屏（viewport 的 80% 区域居中）
- 字体少、清晰（正文 20px，标题 24px）

---

### 交互流程

**展开状态（默认）**
- 全屏半透明 Panel 覆盖游戏画面
- 显示当前提示文字
- 玩家点击"收起"按钮 → 收起 Panel
- 或者点击Overlay 外部区域 → 收起 Panel

**收起状态**
- 整个 PanelContainer 隐藏（`visible = false`）→ 玩家可正常点击炸弹模块
- 屏幕右下角显示一个小型浮动按钮"提示"（FloatButton）
- 点击浮动按钮 → 重新展开全屏 Panel

**翻页**
- 去除时间等待的翻页
- 玩家点击 剪线模块后，自动展开 剪线模块的提示，并等待玩家收起
- 玩家点击 符号键盘模块后，自动展开 键盘模块提示

**自动展开**
- `hint_updated` 信号触发 → 无论当前是否收起，自动展开 Panel 显示新提示
- 玩家看完后自行收起，继续操作

---

### 提示内容

**开屏（welcome）**
你应该让你的同伴点击 "我是拆弹专家" 来获得拆弹说明书。
这是一份危险的工作，多数情况下，你都应该在拆弹专家的指导下完成工作。
但在教程模式中，我会为你提供帮助。
接下来，请先点击接线模块，再解决按钮模块。

**接线模块提示（wire_hint）**
- 4根电线规则说明（按顺序判断）
- 本关具体答案提示（规则3，剪第1根红线）
- 引导下一步：符号键盘模块

**按钮模块提示（button_hint）**
- 找唯一包含4个符号的列
- 本关具体顺序：Ϙ → Ѧ → ƛ → Ѣ

**完成提示（complete_hint）**
- 教程结束总结
- 引导进入完整模式

---

### 场景结构（TutorialHint.tscn）

```
TutorialHint (Control, full rect, mouse_filter=IGNORE)
├── PanelContainer (90% screen, semi-transparent)
│   └── MarginContainer
│       └── VBoxContainer
│           ├── HeaderRow (HBox)
│           │   └── TitleLabel
│           ├── HintLabel (RichTextLabel, SIZE_EXPAND_FILL)
│           └── ToggleButton ("收起")
└── FloatButton (Button, bottom-right corner, hidden when panel visible)
```

### 改动文件
- `TutorialHint.tscn` — 加 FloatButton 节点
- `TutorialHint.gd` — toggle 改为控制整个 panel.visible，FloatButton 控制重新展开，修正文字
