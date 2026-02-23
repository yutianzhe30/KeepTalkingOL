extends Control

const ButtonModule = preload("res://Scripts/Modules/ButtonModule.gd")
var TARGET_FONT = preload("res://Assets/Font/DejaVuSans.ttf")

@onready var grid = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var back_btn = $PanelContainer/MarginContainer/VBoxContainer/BackButton

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	_populate_grid()

func _populate_grid():
	var all_symbols = []
	for list in ButtonModule.LISTS:
		for symbol in list:
			if not symbol in all_symbols:
				all_symbols.append(symbol)
				
	for symbol in all_symbols:
		var panel = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(margin)
		
		var label = Label.new()
		label.text = symbol
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 48)
		if TARGET_FONT:
			label.add_theme_font_override("font", TARGET_FONT)
			
		margin.add_child(label)
		grid.add_child(panel)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
