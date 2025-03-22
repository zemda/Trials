shader_type canvas_item;
render_mode blend_add;

uniform vec4 color : source_color;
uniform float glow_radius : hint_range(0.0, 1.0) = 0.5;
uniform float glow_intensity : hint_range(0.1, 2.0) = 0.5;

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    
    float alpha = smoothstep(glow_radius, 0.0, dist) * glow_intensity;
    COLOR = color;
    COLOR.a *= alpha;
}