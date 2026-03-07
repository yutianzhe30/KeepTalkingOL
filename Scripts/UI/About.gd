extends Control

@onready var rich_text_label = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel
@onready var back_btn = $PanelContainer/MarginContainer/VBoxContainer/BackButton
const ButtonModule = preload("res://Scripts/Modules/ButtonModule.gd")
var TARGET_FONT = preload("res://Assets/Font/DejaVuSans.ttf")

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	_load_credits()
	_load_symbols()

func _load_symbols():
	var all_symbols = []
	for list in ButtonModule.LISTS:
		for symbol in list:
			if not symbol in all_symbols:
				all_symbols.append(symbol)
	
	var text_to_append = "\n\nDebug Symbols:\n"
	for s in all_symbols:
		text_to_append += s
	rich_text_label.text += text_to_append

func _load_credits():
	var file = FileAccess.open("res://Credit.txt", FileAccess.READ)
	if TARGET_FONT:
		rich_text_label.add_theme_font_override("normal_font", TARGET_FONT)
	if file:
		rich_text_label.text = file.get_as_text()
	else:
		rich_text_label.text = "Could not load Credit.txt"


func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
