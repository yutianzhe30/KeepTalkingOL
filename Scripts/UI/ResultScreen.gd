extends Control

const FALLBACK_FONT = preload("res://Assets/Font/NotoSansSC-Regular.ttf")

@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var desc_label = $CenterContainer/VBoxContainer/DescLabel
@onready var btn = $CenterContainer/VBoxContainer/Button

var _is_win: bool = false
var _time_text: String = "00:00"
var _strikes: int = 0
var _debug_info: String = ""

func setup(is_win: bool, time_text: String, strikes: int, debug_info: String = ""):
	_is_win = is_win
	_time_text = time_text
	_strikes = strikes
	_debug_info = debug_info

func _ready():
	title_label.add_theme_font_override("font", FALLBACK_FONT)
	desc_label.add_theme_font_override("font", FALLBACK_FONT)
	
	if _is_win:
		title_label.text = "BOMB DEFUSED!"
		title_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2)) # Green
		desc_label.text = "你的拆蛋技术太强了，奖励你明天不用上班（梦里）\nTime Left: %s\nTotal Strikes: %d" % [_time_text, _strikes]
	else:
		title_label.text = "BOMB EXPLODED!"
		title_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2)) # Red
		desc_label.text = "你已经尽力了，但是并没有阻止它，但往好了看，起码明天不用上班了 :)\nSurviving Time: %s\nTotal Strikes: %d" % [_time_text, _strikes]
		
	# Create the tiny debug info label dynamically
	if _debug_info != "":
		var debug_label = Label.new()
		debug_label.text = _debug_info
		debug_label.add_theme_font_override("font", FALLBACK_FONT)
		debug_label.add_theme_font_size_override("font_size", 12)
		debug_label.modulate = Color(0.7, 0.7, 0.7, 0.8) # Slightly dimmed
		debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Insert it right above the 'Return to Menu' button
		$CenterContainer/VBoxContainer.add_child(debug_label)
		$CenterContainer/VBoxContainer.move_child(debug_label, btn.get_index())

func _on_button_pressed():
	# Clean up the CanvasLayer if it exists so it doesn't persist across scenes
	var parent = get_parent()
	if parent is CanvasLayer:
		parent.queue_free()
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
