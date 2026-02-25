extends Control

@onready var wires_container_1 = %WiresContainer1
@onready var wires_container_2 = %WiresContainer2

var shader = preload("res://Shaders/WireColor.gdshader")
var tex_wire = preload("res://Assets/Pic/Wire.png")
var tex_wire_cut = preload("res://Assets/Pic/Wire_Cut.png")

var test_colors = [
	Color.RED,
	Color.BLUE,
	Color.YELLOW,
	Color.WHITE,
	Color.BLACK,
	Color.GREEN
]

func _ready():
	for color in test_colors:
		var rect1 = _create_wire_rect(tex_wire, color)
		var rect2 = _create_wire_rect(tex_wire_cut, color)
		wires_container_1.add_child(rect1)
		wires_container_2.add_child(rect2)

func _create_wire_rect(tex: Texture2D, color: Color) -> TextureRect:
	var rect = TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(100, 30)
	
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("paint_color", color)
	mat.set_shader_parameter("grayscale_threshold", 0.15)
	
	rect.material = mat
	return rect
