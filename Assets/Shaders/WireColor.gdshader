shader_type canvas_item;

uniform vec4 paint_color : source_color = vec4(1.0);
uniform float grayscale_threshold : hint_range(0.0, 1.0) = 0.15;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Calculate difference between color channels to roughly gauge saturation
    float c_max = max(max(tex_color.r, tex_color.g), tex_color.b);
    float c_min = min(min(tex_color.r, tex_color.g), tex_color.b);
    float saturation = c_max - c_min;
    
    if (tex_color.a > 0.0 && saturation < grayscale_threshold) {
        // Pixel is grayscale (e.g. wire's white body or dark outline).
        // Multiplying by paint_color tints the white efficiently
        // keeping shadows (darker gray) proportionally darker.
        COLOR = vec4((tex_color.rgb * paint_color.rgb), tex_color.a);
    } else {
        // Pixel has high saturation (e.g. the yellow copper wire head).
        COLOR = tex_color; 
    }
}
