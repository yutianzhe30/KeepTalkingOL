extends Control

signal wire_cut(wire_instance)

@onready var wire_visual = $WireVisual
@onready var button = $Button

var is_cut: bool = false
var is_interactable: bool = true
var wire_color: Color = Color.RED

var tex_wire = preload("res://Assets/Pic/Wire.png")
var tex_wire_cut = preload("res://Assets/Pic/Wire_Cut.png")
var shader = preload("res://Shaders/WireColor.gdshader")

func set_interactable(enabled: bool):
	is_interactable = enabled
	button.disabled = !enabled

func setup(color: Color):
	wire_color = color
	
	wire_visual.texture = tex_wire
	
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("paint_color", color)
	mat.set_shader_parameter("grayscale_threshold", 0.15)
	
	wire_visual.material = mat

func _on_button_pressed():
	if not is_cut:
		cut_wire()

func cut_wire():
	is_cut = true
	
	# The cut image is slightly taller (169px) than the uncut image (147px), although both have the same width (1181px).
	# To ensure the wire doesn't appear to shrink horizontally, we slightly expand the TextureRect height.
	var scale_factor = 169.0 / 147.0
	wire_visual.offset_top = -25.0 * scale_factor
	wire_visual.offset_bottom = 25.0 * scale_factor
	
	wire_visual.texture = tex_wire_cut
	emit_signal("wire_cut", self)
