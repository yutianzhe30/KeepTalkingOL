@tool
extends EditorScript

## 迷宫验证工具
## 在 Godot 编辑器中运行：文件 -> 运行 -> 运行脚本

const MazeData = preload("res://Scripts/Modules/MazeRedDotsData.gd")

func _run():
	print("=== 迷宫数据验证 ===\n")
	
	var all_valid = true
	
	for i in range(MazeData.MAZES.size()):
		var maze_data = MazeData.get_maze(i)
		print("验证迷宫 #%d..." % (i + 1))
		
		# 检查基本属性
		if not maze_data.has("id"):
			push_error("迷宫 #%d 缺少 id" % (i + 1))
			all_valid = false
			continue
		
		if not maze_data.has("maze"):
			push_error("迷宫 #%d 缺少 maze 数据" % (i + 1))
			all_valid = false
			continue
		
		if not maze_data.has("start"):
			push_error("迷宫 #%d 缺少 start" % (i + 1))
			all_valid = false
			continue
		
		if not maze_data.has("exit"):
			push_error("迷宫 #%d 缺少 exit" % (i + 1))
			all_valid = false
			continue
		
		var maze = maze_data["maze"]
		var start = maze_data["start"]
		var exit_pos = maze_data["exit"]
		
		# 检查迷宫尺寸
		if maze.size() != 6:
			push_error("迷宫 #%d 高度不是 6" % (i + 1))
			all_valid = false
			continue
		
		for row in maze:
			if row.size() != 6:
				push_error("迷宫 #%d 宽度不是 6" % (i + 1))
				all_valid = false
				break
		
		# 检查起点和终点是否在范围内
		if start.x < 0 or start.x >= 6 or start.y < 0 or start.y >= 6:
			push_error("迷宫 #%d 起点超出范围" % (i + 1))
			all_valid = false
			continue
		
		if exit_pos.x < 0 or exit_pos.x >= 6 or exit_pos.y < 0 or exit_pos.y >= 6:
			push_error("迷宫 #%d 出口超出范围" % (i + 1))
			all_valid = false
			continue
		
		# 检查起点和终点不是墙
		if maze[start.y][start.x] == 1:
			push_error("迷宫 #%d 起点是墙" % (i + 1))
			all_valid = false
			continue
		
		if maze[exit_pos.y][exit_pos.x] == 1:
			push_error("迷宫 #%d 出口是墙" % (i + 1))
			all_valid = false
			continue
		
		# 检查可解性
		if not MazeData.verify_maze_solvable(maze_data):
			push_error("迷宫 #%d 无解！" % (i + 1))
			all_valid = false
			continue
		
		# 计算最短路径
		var path_length = MazeData.get_shortest_path_length(maze_data)
		print("  ✓ 迷宫 #%d 验证通过，最短路径: %d 步" % [maze_data["id"], path_length])
	
	print("\n=== 验证结果 ===")
	if all_valid:
		print("✓ 所有迷宫验证通过！")
	else:
		push_error("✗ 部分迷宫存在问题")
