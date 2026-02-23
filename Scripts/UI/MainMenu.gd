extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_manual_button_pressed() -> void:
	var url = "https://www.google.com"
	if OS.has_feature("web"):
		var js_code = "window.open('%s', '_blank');" % url
		JavaScriptBridge.eval(js_code)
	else:
		OS.shell_open(url)
