extends Control

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            # Try to request sensors for Web Mobile
            if WebInput:
                print("Requesting WebInput sensors...")
                WebInput.request_sensors()
            get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
