extends Control

signal wire_cut(wire_instance)

@onready var wire_visual = $ColorRect
@onready var cut_overlay = $CutOverlay
@onready var button = $Button

var is_cut: bool = false
var wire_color: Color = Color.RED

func setup(color: Color):
	wire_color = color
	wire_visual.color = color
	cut_overlay.visible = false

func _on_button_pressed():
	if not is_cut:
		cut_wire()

func cut_wire():
	is_cut = true
	cut_overlay.visible = true
	# Visual feedback for cut (e.g., make it transparent or show the break)
	# For now, we put a black box in the middle (CutOverlay)
	emit_signal("wire_cut", self)
