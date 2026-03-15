class_name MazeRedDotsData
## 红点迷宫模块 - 迷宫数据文件
## 所有迷宫均为 8x8 网格 (0-7 索引)
## 1 = 墙, 0 = 通路
## 起点/终点位于边缘格（可从任意边进入）

const MAZES = [
	# ========== 迷宫 #1 ==========
	# 起点: (0,3) 左边缘, 出口: (7,4) 右边缘
	# 最短路径: 10步 难度: easy
	# 路径: →→→↓↓→↓→→→
	{
		"id": 1,
		"maze": [
			[1, 1, 1, 1, 1, 1, 1, 1],
			[1, 0, 1, 0, 0, 1, 0, 1],
			[1, 0, 1, 0, 1, 0, 0, 1],
			[0, 0, 0, 0, 1, 0, 1, 1],
			[1, 1, 0, 1, 0, 0, 0, 0],
			[1, 1, 0, 0, 0, 1, 0, 1],
			[1, 1, 1, 0, 1, 1, 0, 1],
			[1, 1, 1, 1, 1, 1, 1, 1],
		],
		"start": Vector2i(0, 3),
		"exit":  Vector2i(7, 4),
		"difficulty": "easy"
	},

	# ========== 迷宫 #2 ==========
	# 起点: (4,0) 上边缘, 出口: (3,7) 下边缘
	# 最短路径: 10步 难度: medium
	# 路径: ↓→→↓↓↓←↓↓↓
	{
		"id": 2,
		"maze": [
			[1, 1, 1, 1, 0, 1, 1, 1],
			[1, 0, 0, 1, 0, 0, 1, 1],
			[1, 0, 1, 1, 0, 0, 0, 1],
			[1, 0, 0, 0, 1, 0, 1, 1],
			[1, 1, 0, 0, 0, 0, 1, 1],
			[1, 1, 1, 0, 0, 1, 0, 1],
			[1, 1, 1, 0, 1, 1, 0, 1],
			[1, 1, 1, 0, 1, 1, 1, 1],
		],
		"start": Vector2i(4, 0),
		"exit":  Vector2i(3, 7),
		"difficulty": "medium"
	},

	# ========== 迷宫 #3 ==========
	# 起点: (0,1) 左边缘, 出口: (6,7) 下边缘
	# 最短路径: 12步 难度: medium
	{
		"id": 3,
		"maze": [
			[1, 1, 1, 1, 1, 1, 1, 1],
			[0, 0, 1, 1, 1, 1, 1, 1],
			[1, 0, 0, 0, 1, 0, 0, 1],
			[1, 1, 0, 1, 0, 0, 1, 1],
			[1, 1, 0, 0, 0, 1, 0, 1],
			[1, 1, 1, 0, 1, 1, 0, 1],
			[1, 1, 1, 0, 0, 0, 0, 1],
			[1, 1, 1, 1, 1, 1, 0, 1],
		],
		"start": Vector2i(0, 1),
		"exit":  Vector2i(6, 7),
		"difficulty": "medium"
	},

	# ========== 迷宫 #4 ==========
	# 起点: (7,2) 右边缘, 出口: (0,6) 左边缘
	# 最短路径: 13步 难度: hard
	{
		"id": 4,
		"maze": [
			[1, 1, 1, 1, 1, 1, 1, 1],
			[1, 0, 0, 0, 1, 0, 0, 1],
			[1, 0, 1, 1, 0, 1, 0, 0],
			[1, 0, 0, 1, 0, 0, 1, 1],
			[1, 1, 0, 0, 0, 1, 0, 1],
			[1, 0, 0, 1, 0, 0, 0, 1],
			[0, 0, 1, 1, 1, 0, 1, 1],
			[1, 1, 1, 1, 1, 1, 1, 1],
		],
		"start": Vector2i(7, 2),
		"exit":  Vector2i(0, 6),
		"difficulty": "hard"
	},

	# ========== 迷宫 #5 ==========
	# 起点: (2,0) 上边缘, 出口: (5,7) 下边缘
	# 最短路径: 12步 难度: medium
	{
		"id": 5,
		"maze": [
			[1, 1, 0, 1, 1, 1, 1, 1],
			[1, 0, 0, 0, 1, 0, 0, 1],
			[1, 0, 1, 0, 0, 0, 1, 1],
			[1, 0, 1, 1, 0, 1, 0, 1],
			[1, 1, 0, 1, 0, 0, 0, 1],
			[1, 1, 0, 0, 0, 1, 0, 1],
			[1, 1, 1, 0, 1, 0, 0, 1],
			[1, 1, 1, 1, 1, 0, 1, 1],
		],
		"start": Vector2i(2, 0),
		"exit":  Vector2i(5, 7),
		"difficulty": "medium"
	},

	# ========== 迷宫 #6 ==========
	# 起点: (0,4) 左边缘, 出口: (7,3) 右边缘
	# 最短路径: 10步 难度: medium
	{
		"id": 6,
		"maze": [
			[1, 1, 1, 1, 1, 1, 1, 1],
			[1, 0, 0, 0, 1, 0, 0, 1],
			[1, 0, 1, 0, 0, 0, 1, 1],
			[1, 0, 1, 1, 1, 0, 0, 0],
			[0, 0, 0, 1, 0, 0, 0, 1],
			[1, 1, 0, 0, 0, 1, 0, 1],
			[1, 1, 1, 0, 1, 0, 0, 1],
			[1, 1, 1, 1, 1, 1, 1, 1],
		],
		"start": Vector2i(0, 4),
		"exit":  Vector2i(7, 3),
		"difficulty": "medium"
	},

	# ========== 迷宫 #7 ==========
	# 起点: (1,7) 下边缘, 出口: (6,0) 上边缘
	# 最短路径: 12步 难度: hard
	{
		"id": 7,
		"maze": [
			[1, 1, 1, 1, 1, 1, 0, 1],
			[1, 0, 1, 0, 1, 0, 0, 1],
			[1, 0, 1, 0, 0, 0, 1, 1],
			[1, 0, 0, 0, 1, 0, 1, 1],
			[1, 1, 1, 0, 1, 0, 0, 1],
			[1, 1, 0, 0, 0, 1, 0, 1],
			[1, 0, 0, 1, 0, 1, 0, 1],
			[1, 0, 1, 1, 1, 1, 1, 1],
		],
		"start": Vector2i(1, 7),
		"exit":  Vector2i(6, 0),
		"difficulty": "hard"
	},

	# ========== 迷宫 #8 ==========
	# 起点: (7,5) 右边缘, 出口: (0,2) 左边缘
	# 最短路径: 12步 难度: hard
	{
		"id": 8,
		"maze": [
			[1, 1, 1, 1, 1, 1, 1, 1],
			[1, 0, 0, 0, 1, 0, 1, 1],
			[0, 0, 1, 0, 0, 0, 1, 1],
			[1, 0, 1, 1, 0, 1, 0, 1],
			[1, 0, 0, 1, 0, 0, 0, 1],
			[1, 1, 0, 0, 0, 1, 0, 0],
			[1, 1, 1, 0, 1, 1, 0, 1],
			[1, 1, 1, 1, 1, 1, 1, 1],
		],
		"start": Vector2i(7, 5),
		"exit":  Vector2i(0, 2),
		"difficulty": "hard"
	},
]

## 获取迷宫数据
static func get_maze(index: int) -> Dictionary:
	if index < 0 or index >= MAZES.size():
		return MAZES[0]
	return MAZES[index]

## 获取随机迷宫索引
static func get_random_maze_index() -> int:
	return randi_range(0, MAZES.size() - 1)

## 验证迷宫可解性 (BFS算法)
static func verify_maze_solvable(maze_data: Dictionary) -> bool:
	var maze = maze_data["maze"]
	var start = maze_data["start"]
	var exit = maze_data["exit"]
	var width = maze[0].size()
	var height = maze.size()

	var queue = [start]
	var visited = {}
	visited[start] = true

	var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

	while queue.size() > 0:
		var current = queue.pop_front()

		if current == exit:
			return true

		for dir in directions:
			var next = current + dir

			if next.x < 0 or next.x >= width or next.y < 0 or next.y >= height:
				continue
			if visited.has(next):
				continue
			if maze[next.y][next.x] == 1:
				continue

			visited[next] = true
			queue.append(next)

	return false

## 计算最短路径长度
static func get_shortest_path_length(maze_data: Dictionary) -> int:
	var maze = maze_data["maze"]
	var start = maze_data["start"]
	var exit = maze_data["exit"]
	var width = maze[0].size()
	var height = maze.size()

	var queue = [[start, 0]]
	var visited = {}
	visited[start] = true

	var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

	while queue.size() > 0:
		var item = queue.pop_front()
		var current = item[0]
		var distance = item[1]

		if current == exit:
			return distance

		for dir in directions:
			var next = current + dir

			if next.x < 0 or next.x >= width or next.y < 0 or next.y >= height:
				continue
			if visited.has(next):
				continue
			if maze[next.y][next.x] == 1:
				continue

			visited[next] = true
			queue.append([next, distance + 1])

	return -1
