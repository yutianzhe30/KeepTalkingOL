class_name MazeRedDotsModule
extends "res://Scripts/Modules/BaseModule.gd"

## 红点迷宫模块 (Maze Blind Navigation)
## 核心机制：拆弹者只能看到两个点（自己和出口），需要通过手册导航走出迷宫

const MazeData = preload("res://Scripts/Modules/MazeRedDotsData.gd")

@export var cell_size: int = 40

# 迷宫数据
var maze: Array[Array] = []
var maze_width: int = 6
var maze_height: int = 6
var player_pos: Vector2i = Vector2i(0, 0)
var exit_pos: Vector2i = Vector2i(0, 0)
var start_pos: Vector2i = Vector2i(0, 0)
var current_maze_id: int = 0

# 玩家当前朝向（0=北, 1=东, 2=南, 3=西）
var player_facing: int = 1

# 统计数据
var steps_taken: int = 0
var wall_hits: int = 0

# 撞墙闪烁
var _wall_flash_alpha: float = 0.0
var _flash_tween: Tween

# 颜色
const COLOR_PLAYER     = Color(0.2, 1.0, 0.2)
const COLOR_EXIT       = Color(1.0, 0.15, 0.15)
const COLOR_EXIT_NEAR  = Color(1.0, 0.55, 0.1)
const COLOR_GRID       = Color(0.28, 0.28, 0.28)     # 浅灰格线（始终显示）
const COLOR_WALL       = Color(0.55, 0.55, 0.55)     # debug墙体填充
const COLOR_WALL_EDGE  = Color(0.35, 0.35, 0.35)     # debug墙体描边
const COLOR_FLASH      = Color(1.0, 0.12, 0.12)      # 撞墙闪红边框

# 声音
var audio_player: AudioStreamPlayer


func _ready():
	_setup_audio()
	_generate_maze()
	_setup_ui()
	_update_display()


func _setup_audio():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func _generate_maze():
	if GameState.simple_mode:
		_load_maze_by_index(0)
	else:
		var maze_index = MazeData.get_random_maze_index()
		_load_maze_by_index(maze_index)


func _load_maze_by_index(index: int):
	var maze_data = MazeData.get_maze(index)

	maze.clear()
	for row in maze_data["maze"]:
		maze.append(row.duplicate())

	maze_width  = maze[0].size()
	maze_height = maze.size()
	start_pos   = maze_data["start"]
	exit_pos    = maze_data["exit"]
	current_maze_id = maze_data["id"]
	player_pos  = start_pos
	player_facing = randi_range(0, 3)

	if OS.is_debug_build():
		if not MazeData.verify_maze_solvable(maze_data):
			push_error("Maze %d is not solvable!" % current_maze_id)
		else:
			var path_length = MazeData.get_shortest_path_length(maze_data)
			print("Maze %d loaded: shortest path = %d steps" % [current_maze_id, path_length])


func _setup_ui():
	# 节点已在 .tscn 中预定义，此处只做连线 + 动态创建按钮

	# 连接迷宫绘制信号
	var maze_panel = get_node("MainContainer/MazePanel") as Panel
	_connect_draw(maze_panel)

	# 方向按钮（场景中 ButtonGrid 为空，需动态添加）
	var btn_grid = get_node("MainContainer/Controls/ButtonGrid") as GridContainer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(40, 40)
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(40, 40)
	btn_grid.add_child(spacer1)
	btn_grid.add_child(_create_dir_button("↑", 0))
	btn_grid.add_child(spacer2)
	btn_grid.add_child(_create_dir_button("←", 3))
	btn_grid.add_child(_create_dir_button("↓", 2))
	btn_grid.add_child(_create_dir_button("→", 1))

	# 连接确认按钮信号
	var confirm_btn = get_node("MainContainer/ConfirmButton") as Button
	confirm_btn.pressed.connect(_on_confirm_pressed)

	# 迷宫ID标签（仅 debug 模式，动态插入到容器顶部）
	if OS.is_debug_build():
		var id_label = Label.new()
		id_label.name = "MazeIdLabel"
		id_label.text = "迷宫 #%d" % current_maze_id
		id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var container = get_node("MainContainer") as VBoxContainer
		container.add_child(id_label)
		container.move_child(id_label, 0)


func _create_dir_button(text: String, direction: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(40, 40)
	btn.pressed.connect(_on_dir_pressed.bind(direction))
	return btn


# ─────────────────────────────────────────────
#  输入处理
# ─────────────────────────────────────────────

func _on_dir_pressed(direction: int):
	if state != ModuleState.ACTIVE:
		return

	var abs_direction: int = player_facing  # default: forward
	match direction:
		0: abs_direction = player_facing
		1: abs_direction = (player_facing + 1) % 4
		2: abs_direction = (player_facing + 2) % 4
		3: abs_direction = (player_facing + 3) % 4

	var new_pos = player_pos + _dir_to_vector(abs_direction)

	if _is_valid_move(new_pos):
		player_pos = new_pos
		steps_taken += 1
		_play_move_sound()
		_check_win_condition()
	else:
		wall_hits += 1
		_trigger_wall_flash()
		_play_wall_hit_sound(abs_direction)

	_update_display()


func _dir_to_vector(dir: int) -> Vector2i:
	match dir:
		0: return Vector2i(0, -1)
		1: return Vector2i(1, 0)
		2: return Vector2i(0, 1)
		3: return Vector2i(-1, 0)
	return Vector2i(0, 0)


func _is_valid_move(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= maze_width or pos.y < 0 or pos.y >= maze_height:
		return false
	return maze[pos.y][pos.x] == 0


# ─────────────────────────────────────────────
#  撞墙闪烁
# ─────────────────────────────────────────────

func _trigger_wall_flash():
	_wall_flash_alpha = 1.0
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_method(_set_flash_alpha, 1.0, 0.0, 0.4)


func _set_flash_alpha(alpha: float):
	_wall_flash_alpha = alpha
	var maze_panel = get_node_or_null("MainContainer/MazePanel") as Panel
	if maze_panel:
		maze_panel.queue_redraw()


# ─────────────────────────────────────────────
#  音效（占位）
# ─────────────────────────────────────────────

func _play_move_sound():
	pass


func _play_wall_hit_sound(_direction: int):
	pass


# ─────────────────────────────────────────────
#  游戏逻辑
# ─────────────────────────────────────────────

func _check_win_condition():
	var confirm_btn = get_node_or_null("MainContainer/ConfirmButton") as Button
	if confirm_btn:
		confirm_btn.disabled = (player_pos != exit_pos)


func _on_confirm_pressed():
	if player_pos == exit_pos:
		mark_solved()
	else:
		mark_failed()


# ─────────────────────────────────────────────
#  显示更新
# ─────────────────────────────────────────────

func _update_display():
	var maze_panel = get_node_or_null("MainContainer/MazePanel") as Panel
	if maze_panel:
		maze_panel.queue_redraw()

	var status_label = get_node_or_null("MainContainer/StatusLabel") as Label
	if status_label:
		status_label.text = "步数: %d | 撞墙: %d" % [steps_taken, wall_hits]


func _connect_draw(maze_panel: Panel):
	if not maze_panel.is_connected("draw", _draw_maze):
		maze_panel.draw.connect(_draw_maze)
	maze_panel.queue_redraw()


# ─────────────────────────────────────────────
#  绘制
# ─────────────────────────────────────────────

func _draw_maze():
	var panel = get_node_or_null("MainContainer/MazePanel") as Panel
	if not panel:
		return

	# 计算居中偏移
	var offset = Vector2(
		(panel.size.x - maze_width  * cell_size) / 2.0,
		(panel.size.y - maze_height * cell_size) / 2.0
	)

	# 1. 黑色背景
	panel.draw_rect(Rect2(Vector2.ZERO, panel.size), Color(0.08, 0.08, 0.08))

	# 2. 浅灰格线（始终可见，帮助玩家定位）
	_draw_grid(panel, offset)

	# 3. 墙体（debug 模式）
	if OS.is_debug_build():
		_draw_walls(panel, offset)

	# 4. 出口红点（距离 ≤ 3 时可见）
	var dist = player_pos.distance_to(exit_pos)
	if dist <= 3.0 or OS.is_debug_build():
		var exit_center = _cell_center(exit_pos, offset)
		var exit_color  = COLOR_EXIT if dist <= 1.0 else COLOR_EXIT_NEAR
		var exit_alpha  = 1.0 if dist <= 2.0 or OS.is_debug_build() else 0.5
		panel.draw_circle(exit_center, cell_size * 0.30, Color(exit_color, exit_alpha))

	# 5. 玩家绿点 + 朝向箭头
	var player_center = _cell_center(player_pos, offset)
	panel.draw_circle(player_center, cell_size * 0.35, COLOR_PLAYER)

	var arrow_dirs := [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	var arrow_end  = player_center + arrow_dirs[player_facing] * (cell_size * 0.25)
	panel.draw_line(player_center, arrow_end, Color(0, 0, 0, 0.85), 2.5)

	# 6. 撞墙闪烁边框（最顶层）
	if _wall_flash_alpha > 0.01:
		var maze_rect = Rect2(offset, Vector2(maze_width * cell_size, maze_height * cell_size))
		panel.draw_rect(maze_rect, Color(COLOR_FLASH, _wall_flash_alpha), false, 4.0)


func _draw_grid(panel: Panel, offset: Vector2):
	## 绘制浅灰格线，让玩家感知格子位置
	var w = maze_width  * cell_size
	var h = maze_height * cell_size
	for x in range(maze_width + 1):
		var xp = offset.x + x * cell_size
		panel.draw_line(Vector2(xp, offset.y), Vector2(xp, offset.y + h), COLOR_GRID, 1.0)
	for y in range(maze_height + 1):
		var yp = offset.y + y * cell_size
		panel.draw_line(Vector2(offset.x, yp), Vector2(offset.x + w, yp), COLOR_GRID, 1.0)


func _draw_walls(panel: Panel, offset: Vector2):
	## debug 模式：用浅灰色填充墙格
	for y in range(maze_height):
		for x in range(maze_width):
			if maze[y][x] == 1:
				var pos = Vector2(x * cell_size, y * cell_size) + offset
				panel.draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), COLOR_WALL)
				panel.draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), COLOR_WALL_EDGE, false, 1.0)


# ─────────────────────────────────────────────
#  辅助
# ─────────────────────────────────────────────

func _cell_center(grid_pos: Vector2i, offset: Vector2) -> Vector2:
	return Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size) + offset + Vector2(cell_size * 0.5, cell_size * 0.5)


func get_debug_info() -> String:
	var info = "Maze Red Dots Module (ID: %d):\n" % current_maze_id
	info += "Player at (%d, %d), Exit at (%d, %d)\n" % [player_pos.x, player_pos.y, exit_pos.x, exit_pos.y]
	info += "Steps: %d, Wall hits: %d\n" % [steps_taken, wall_hits]
	info += "Maze Layout (P=player, E=exit, #=wall, .=path):\n"
	for y in range(maze_height):
		var line = ""
		for x in range(maze_width):
			if Vector2i(x, y) == player_pos:
				line += "P"
			elif Vector2i(x, y) == exit_pos:
				line += "E"
			elif maze[y][x] == 1:
				line += "#"
			else:
				line += "."
		info += line + "\n"
	return info


func get_maze_data() -> Dictionary:
	return {
		"id": current_maze_id,
		"maze": maze,
		"width": maze_width,
		"height": maze_height,
		"player_start": start_pos,
		"exit": exit_pos,
		"player_facing": player_facing
	}
