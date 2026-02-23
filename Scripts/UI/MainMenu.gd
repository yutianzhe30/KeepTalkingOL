extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_manual_button_pressed() -> void:
	# Assume the PDF is placed directly next to the exported executable or HTML file
	var pdf_filename = "MANUAL_CN.pdf"
	
	if OS.has_feature("web"):
		# On a web server, a relative path opens relative to the index.html
		var js_code = "window.open('%s', '_blank');" % pdf_filename
		JavaScriptBridge.eval(js_code)
	elif OS.has_feature("editor"):
		# When playing from the Godot Editor, look for it in the project root
		OS.shell_open(ProjectSettings.globalize_path("res://" + pdf_filename))
	else:
		# For exported PC builds (Windows/Mac/Linux), find it next to the .exe
		var exec_dir = OS.get_executable_path().get_base_dir()
		var pdf_path = exec_dir.path_join(pdf_filename)
		OS.shell_open(pdf_path)

func _on_debug_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/FontDebug.tscn")
