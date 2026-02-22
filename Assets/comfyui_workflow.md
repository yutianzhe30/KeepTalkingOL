---
description: 如何使用 ComfyUI 生成拆弹游戏所需的 2D 游戏素材
---

# ComfyUI 生成游戏素材工作流 (Keep Talking Game Assets)

这篇文档介绍了如何使用 ComfyUI 为我们的解谜游戏（类似 Keep Talking and Nobody Explodes）生成所需的 2D 游戏素材，并梳理了目前游戏开发所需要的具体资产列表。

## 1. 游戏需要哪些核心素材？

基于目前游戏内的模块（Timer, Radio, Wire, ECG, Button），你需要生成以下类别的游戏素材：

### 基础底板与框架 (Base & Casings)
- **炸弹主体手提箱**：金属或军用塑料质感的外壳，带有凹槽、把手和阴影底座。
- **模块底板 (Module Plates)**：所有模块通用的正方形金属或塑料底板。建议生成“全新”、“带有磨损/划痕”的不同变体。
- **固定组件**：用于将底板固定在炸弹上的螺丝、铆钉（需要带透明通道的独立小图标）。

### 交互组件 (Interactive Elements)
- **按钮 (Button Module)**：
  - 圆形和方形的大按钮（需要表现“未按下”和“已按下”两种厚度/阴影状态）。
  - 需要不同颜色的变体（红、蓝、黄、白等，可与 `GlobalColors.gd` 中的色调匹配）。
- **电线 (Wire Module)**：
  - 各种颜色的电线束（红、白、蓝、黄、黑等）。
  - 连接电线两端的基座插槽/铜排。
  - **关键状态**：未剪断的完整电线，以及被剪断的断口散开状态。
- **旋钮与开关 (Radio Module)**：
  - 无线电频段的齿轮旋钮、音量旋钮（带防滑纹路）。
  - 上下拨动的金属扭子开关（Toggle Switches）。
- **ECG与信号器 (ECG Module)**：
  - 带有绿色发光网格的类似示波器的屏幕背板。
  - 信号调节推子或旋钮。

### 指示器与装饰 (Indicators & Details)
- **LED 状态指示灯**：小圆灯图标，包括未点亮（暗色）、点亮（红、绿亮光），用于显示模块错误（Strikes）或已解除。
- **倒计时屏幕 (Timer Module)**：数字数码管 (Seven-segment display) 的玻璃屏幕背板。
- **环境贴花 (Decals)**：序列号标签贴纸、电池、电池匣、各种电子接口（并行端口、DVI 等）。

---

## 2. ComfyUI 推荐生成工作流 (Workflow Steps)

要稳定生成背景透明且风格一致的 2D 游戏资产，建议使用以下工作流：

### 核心思路：大模型 + ControlNet 统一外形 + Rembg 自动抠图

1. **选择 Checkpoint (大模型)**：
   - 建议选用对 2D/2.5D 物体感知良好的模型，例如 `ReV Animated`, `DreamShaper`，或者专门的 Game Asset / Icon 微调模型（可选择 SDXL 搭配）。

2. **编写 Prompts (提示词)**：
   - **正向提示词 (Positive)**：`2d game asset, UI element, [例如: a red glossy push button], flat design, top-down view, clean edges, isolated on white background, metallic texture, high quality.`
   - **反向提示词 (Negative)**：`3d, perspective, isometric, messy, text, watermark, complex background, shadow overflow.`

3. **使用 ControlNet (形状控制)**：
   - **场景**：当你需要生成尺寸完全一致的模块底板时（比如 512x512）以确保在 Godot 中完美拼接。
   - **操作**：手绘一个简单的正方形或圆形线稿图，输入到 `ControlNet Lineart` 或 `Canny` 节点中，将权重设为 0.7 左右。这能保证每次生成的形状边缘完全一样，只是内部纹理或材质发生变化。

4. **Image Rembg (背景去除)**：
   - 生成游戏素材最繁琐的是抠图。在 `VAE Decode` 节点之后，直接串接一块 `Image Rembg` 节点（安装 ComfyUI-rembg 插件）。
   - 让它自动去除白色/纯色背景，输出带 Alpha 通道的 `.png`，即可直接拖入 Godot。

5. **风格一致性 (Color & Style)**：
   - 为了贴合近期的 `GlobalColors.gd` 扁平化重构任务，提示词中可加入 `flat pastel colors, modern ui`。
   - 可以为特定部件训练一个小型 LoRA（比如 Keep Talking 原版画风），挂载在生成链路中以确保所有输出素材具备相同的“军用工业风”。

### ComfyUI 基础连线顺序简述：
`Load Checkpoint` -> `CLIP Text Encode (正负提示词)` -> `Empty Latent Image (设置宽高)` -> `KSampler (加载 ControlNet)` -> `VAE Decode` -> `Image Rembg (背景去除)` -> `Save Image`.
