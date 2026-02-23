extends PanelContainer
class_name SerialNumberModule

var serial_number: String = ""

func _ready() -> void:
	_generate_serial_number()
	var label = get_node_or_null("CenterContainer/VBoxContainer/SerialLabel")
	if label:
		label.text = serial_number

func get_serial_number() -> String:
	var label = get_node_or_null("CenterContainer/VBoxContainer/SerialLabel")
	if label and label.text != "":
		return label.text
	if serial_number == "":
		_generate_serial_number()
	return serial_number

func _generate_serial_number() -> void:
	if (serial_number != ""):
		return
	# 推荐长度: 6位 (5位随机混合 + 1位数字结尾)
	var chars = "ABCDEFGHJKLMNPQRSTUVWXZ" # 排除 O, I 以免和视觉上的 0, 1 混淆
	var nums = "0123456789"
	var all_chars = chars + nums
	
	for i in range(5):
		serial_number += all_chars[randi() % all_chars.length()]
		
	# 确保前5位中至少包含一个字母（这也是 KTANE 类解谜的常见设计）
	var has_letter = false
	for i in range(5):
		if chars.find(serial_number[i]) != -1:
			has_letter = true
			break
			
	if not has_letter:
		var replace_idx = randi() % 5
		var new_char = chars[randi() % chars.length()]
		serial_number = serial_number.substr(0, replace_idx) + new_char + serial_number.substr(replace_idx + 1)
		
	# 最后一位固定为数字，方便作为后续解谜规则的基础（比如“如果序列号最后一位是偶数”）
	serial_number += nums[randi() % nums.length()]

func get_debug_info() -> String:
	return "Serial Number: " + serial_number
