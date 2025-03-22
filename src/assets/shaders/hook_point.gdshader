shader_type canvas_item;
render_mode blend_add;

uniform vec4 base_color : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.6, 0.9, 1.0, 0.8);

uniform float line_height : hint_range(1.0, 10.0) = 3.0;
uniform float glow_intensity : hint_range(0.5, 5.0) = 1.8;
uniform float glow_width : hint_range(0.01, 0.3) = 0.1;

uniform float pulse_speed : hint_range(0.1, 5.0) = 1.5;
uniform float shimmer_speed : hint_range(0.1, 5.0) = 2.0;
uniform float shimmer_width : hint_range(0.1, 1.0) = 0.4;

void fragment() {
    vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 uv = UV;
    
    float line_pos_y = 1.0 - line_height / 20.0;
    float line_size = line_height / 20.0;
    
    float dist_to_line = abs(uv.y - line_pos_y);
    float normalized_dist = dist_to_line / line_size;
    
    if (normalized_dist < 1.0) {
        float line_intensity = smoothstep(1.0, 0.0, normalized_dist);
        
        float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
        
        float shimmer_pos = fract(uv.x - TIME * shimmer_speed);
        float shimmer = smoothstep(shimmer_width, 0.0, abs(shimmer_pos - 0.5)) * 0.4;
        
        float noise = fract(sin(uv.x * 50.0 + uv.y * 30.0 + TIME * 0.5) * 5000.0) * 0.1;
        vec4 line = base_color * (line_intensity + shimmer + noise) * pulse;
        
        float glow = smoothstep(glow_width, 0.0, normalized_dist - 0.5);
        vec4 glow_effect = glow_color * glow * glow_intensity * pulse;
        
        final_color = line + glow_effect;
    }
    
    final_color.a = min(final_color.a, 1.0);
    COLOR = final_color;
}