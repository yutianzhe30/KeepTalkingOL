class_name MazeRedDotsModule
extends "res://Scripts/Modules/BaseModule.gd"

## 红点迷宫模块 (Maze Blind Navigation)
## 核心机制：拆弹者只能看到两个点（自己和出口），需要通过手册导航走出迷宫

const MazeData = preload("res://Scripts/Modules/MazeRedDotsData.gd")

# 迷宫数据
var maze: Array[Array] = []
var maze_width: int = 8
var maze_height: int = 8
var player_pos: Vector2i = Vector2i(0, 0)
var exit_pos: Vector2i = Vector2i(0, 0)
var start_pos: Vector2i = Vector2i(0, 0)
var current_maze_id: int = 0

# 统计数据
var steps_taken: int = 0
var wall_hits: int = 0

# 激活状态（点击后才接受方向输入）
var _input_focused: bool = false
var _pulse_time: float = 0.0

# 撞墙闪烁
var _wall_flash_alpha: float = 0.0
var _flash_tween: Tween

# Debug 模式（按 F2 切换）：显示墙体
var _debug_mode: bool = false

# 颜色（玩家=红点，出口=绿点）
const COLOR_PLAYER     = Color(1.0, 0.15, 0.15)
const COLOR_EXIT       = Color(0.2, 1.0, 0.2)
const COLOR_EXIT_NEAR  = Color(0.6, 1.0, 0.3)
const COLOR_GRID       = Color(0.28, 0.28, 0.28)
const COLOR_WALL       = Color(0.55, 0.55, 0.55)
const COLOR_WALL_EDGE  = Color(0.35, 0.35, 0.35)
const COLOR_FLASH      = Color(1.0, 0.12, 0.12)

# 声音
var audio_player: AudioStreamPlayer


func _ready():
	_setup_audio()
	_generate_maze()
	_setup_ui()
	_update_display()


func _process(delta: float) -> void:
	if _input_focused or state != ModuleState.ACTIVE:
		return
	_pulse_time += delta
	var maze_panel = get_node_or_null("MainContainer/MazePanel") as Panel
	if maze_panel:
		maze_panel.queue_redraw()


func _setup_audio():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func _generate_maze():
	_load_maze_by_index(MazeData.get_random_maze_index())


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

	if OS.is_debug_build():
		if not MazeData.verify_maze_solvable(maze_data):
			push_error("Maze %d is not solvable!" % current_maze_id)
		else:
			var path_length = MazeData.get_shortest_path_length(maze_data)
			print("Maze %d loaded: shortest path = %d steps" % [current_maze_id, path_length])


func _setup_ui():
	var maze_panel = get_node("MainContainer/MazePanel") as Panel
	_connect_draw(maze_panel)
	maze_panel.gui_input.connect(_on_maze_panel_input)


# ─────────────────────────────────────────────
#  输入处理
# ─────────────────────────────────────────────

func _on_maze_panel_input(event: InputEvent) -> void:
	if state != ModuleState.ACTIVE:
		return
	var clicked := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked = true
	elif event is InputEventScreenTouch and event.pressed:
		clicked = true
	if clicked and not _input_focused:
		_input_focused = true
		var maze_panel = get_node_or_null("MainContainer/MazePanel") as Panel
		if maze_panel:
			maze_panel.queue_redraw()


func _move_player(direction: int):
	if state != ModuleState.ACTIVE or not _input_focused:
		return

	var new_pos = player_pos + _dir_to_vector(direction)

	if _is_valid_move(new_pos):
		player_pos = new_pos
		steps_taken += 1
		_play_move_sound()
		_check_win_condition()
	else:
		wall_hits += 1
		_trigger_wall_flash()
		_play_wall_hit_sound()

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


func _unhandled_input(event: InputEvent):
	## F2: 切换 debug 模式（显示/隐藏墙体）
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			_debug_mode = not _debug_mode
			_update_display()
			get_viewport().set_input_as_handled()
			return

	## 键盘方向键 / WASD / 屏幕D-pad
	if state != ModuleState.ACTIVE or not _input_focused:
		return
	var dir := -1
	if   event.is_action_pressed("up"):    dir = 0
	elif event.is_action_pressed("right"): dir = 1
	elif event.is_action_pressed("down"):  dir = 2
	elif event.is_action_pressed("left"):  dir = 3
	if dir != -1:
		_move_player(dir)
		get_viewport().set_input_as_handled()


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


func _play_wall_hit_sound():
	pass


# ─────────────────────────────────────────────
#  游戏逻辑
# ─────────────────────────────────────────────

func _check_win_condition():
	if player_pos == exit_pos:
		mark_solved()


# ─────────────────────────────────────────────
#  显示更新
# ─────────────────────────────────────────────

func _update_display():
	var maze_panel = get_node_or_null("MainContainer/MazePanel") as Panel
	if maze_panel:
		maze_panel.queue_redraw()


func _connect_draw(maze_panel: Panel):
	if not maze_panel.is_connected("draw", _draw_maze):
		maze_panel.draw.connect(_draw_maze)
	maze_panel.queue_redraw()


# ─────────────────────────────────────────────
#  绘制
# ─────────────────────────────────────────────

func _get_cell_size(panel: Panel) -> float:
	return min(panel.size.x / maze_width, panel.size.y / maze_height)


func _draw_maze():
	var panel = get_node_or_null("MainContainer/MazePanel") as Panel
	if not panel:
		return

	var cs = _get_cell_size(panel)

	# 计算居中偏移
	var offset = Vector2(
		(panel.size.x - maze_width  * cs) / 2.0,
		(panel.size.y - maze_height * cs) / 2.0
	)

	# 1. 黑色背景
	panel.draw_rect(Rect2(Vector2.ZERO, panel.size), Color(0.08, 0.08, 0.08))

	# 2. 墙体（debug 模式）
	if _debug_mode:
		_draw_walls(panel, offset, cs)

	# 3. 浅灰格线
	_draw_grid(panel, offset, cs)

	# 4. 出口点（距离 ≤ 3 时可见，debug 下始终可见）
	var dist = player_pos.distance_to(exit_pos)
	if dist <= 3.0 or _debug_mode:
		var exit_center = _cell_center(exit_pos, offset, cs)
		var exit_color  = COLOR_EXIT if dist <= 1.0 else COLOR_EXIT_NEAR
		var exit_alpha  = 1.0 if dist <= 2.0 or _debug_mode else 0.5
		panel.draw_circle(exit_center, cs * 0.30, Color(exit_color, exit_alpha))

	# 5. 玩家红点
	var player_center = _cell_center(player_pos, offset, cs)
	panel.draw_circle(player_center, cs * 0.35, COLOR_PLAYER)

	# 6. 撞墙闪烁边框
	if _wall_flash_alpha > 0.01:
		var maze_rect = Rect2(offset, Vector2(maze_width * cs, maze_height * cs))
		panel.draw_rect(maze_rect, Color(COLOR_FLASH, _wall_flash_alpha), false, 4.0)

	# 7. 未激活遮罩
	if not _input_focused and state == ModuleState.ACTIVE:
		var pulse = sin(_pulse_time * 2.8) * 0.18 + 0.45
		panel.draw_rect(Rect2(Vector2.ZERO, panel.size), Color(0.0, 0.0, 0.0, pulse))
		var font := ThemeDB.fallback_font
		var font_size := 14
		var text := "TAP TO MOVE"
		var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_x: float = (panel.size.x - text_w) / 2.0
		var text_y: float = panel.size.y / 2.0 + font_size * 0.4
		panel.draw_string(font, Vector2(text_x + 1, text_y + 1), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.6))
		panel.draw_string(font, Vector2(text_x, text_y), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.9))



func _draw_grid(panel: Panel, offset: Vector2, cs: float):
	var w = maze_width  * cs
	var h = maze_height * cs
	for x in range(maze_width + 1):
		var xp = round(offset.x + x * cs)
		panel.draw_line(Vector2(xp, round(offset.y)), Vector2(xp, round(offset.y + h)), COLOR_GRID, 2.0)
	for y in range(maze_height + 1):
		var yp = round(offset.y + y * cs)
		panel.draw_line(Vector2(round(offset.x), yp), Vector2(round(offset.x + w), yp), COLOR_GRID, 2.0)


func _draw_walls(panel: Panel, offset: Vector2, cs: float):
	for y in range(maze_height):
		for x in range(maze_width):
			if maze[y][x] == 1:
				var pos = Vector2(round(x * cs + offset.x), round(y * cs + offset.y))
				var size = Vector2(round(cs), round(cs))
				panel.draw_rect(Rect2(pos, size), COLOR_WALL)
				panel.draw_rect(Rect2(pos, size), COLOR_WALL_EDGE, false, 2.0)


# ─────────────────────────────────────────────
#  辅助
# ─────────────────────────────────────────────

func _cell_center(grid_pos: Vector2i, offset: Vector2, cs: float) -> Vector2:
	return Vector2(grid_pos.x * cs, grid_pos.y * cs) + offset + Vector2(cs * 0.5, cs * 0.5)


func get_debug_info() -> String:
	var info = "Maze Red Dots Module (ID: %d):\n" % current_maze_id
	info += "Player at (%d, %d), Exit at (%d, %d)\n" % [player_pos.x, player_pos.y, exit_pos.x, exit_pos.y]
	info += "Steps: %d, Wall hits: %d\n" % [steps_taken, wall_hits]
	info += "Debug mode: %s\n" % str(_debug_mode)
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
	}
