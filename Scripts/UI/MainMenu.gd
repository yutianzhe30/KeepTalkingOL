extends Control


@onready var warning_panel: PanelContainer = $WarningPanel
@onready var lang_button: Button = $LangButton
@onready var difficulty_option: OptionButton = $CenterContainer/VBoxContainer/DefuserRow/DifficultyOption

func _ready() -> void:
	warning_panel.hide()
	_update_lang_button()
	difficulty_option.add_item("Easy",   GameState.Difficulty.EASY)
	difficulty_option.add_item("Medium", GameState.Difficulty.MEDIUM)
	difficulty_option.add_item("Hard",   GameState.Difficulty.HARD)
	difficulty_option.selected = GameState.Difficulty.MEDIUM

func _update_lang_button() -> void:
	lang_button.text = "EN" if Localization.get_locale().begins_with("zh") else "中文"

func _on_lang_button_pressed() -> void:
	Localization.toggle_locale()
	_update_lang_button()

func _on_tutorial_button_pressed() -> void:
	GameState.simple_mode = true
	get_tree().change_scene_to_file("res://main.tscn")

func _on_start_as_defuser_pressed() -> void:
	GameState.simple_mode = false
	GameState.difficulty = difficulty_option.get_item_id(difficulty_option.selected) as GameState.Difficulty
	warning_panel.show()

func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_start_as_specialist_pressed() -> void:
	var pdf_filename = "MANUAL_CN.pdf"

	if OS.has_feature("web"):
		var js_code = "window.open('%s', '_blank');" % pdf_filename
		JavaScriptBridge.eval(js_code)
	elif OS.has_feature("editor"):
		OS.shell_open(ProjectSettings.globalize_path("res://Export/" + pdf_filename))
	else:
		var exec_dir = OS.get_executable_path().get_base_dir()
		var pdf_path = exec_dir.path_join(pdf_filename)
		if FileAccess.file_exists(pdf_path):
			OS.shell_open(pdf_path)
		else:
			push_error("Manual PDF not found at: " + pdf_path)

func _on_debug_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/About.tscn")

func _on_github_button_pressed() -> void:
	OS.shell_open("https://github.com/yutianzhe30/KeepTalkingOL")
