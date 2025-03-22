shader_type canvas_item;
render_mode blend_add;

uniform vec4 color : source_color;
uniform float pulse_speed = 2.0;

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    float alpha = smoothstep(0.5, 0.0, dist) * mix(0.6, 1.0, pulse);
    
    COLOR = color;
    COLOR.a *= alpha;
}