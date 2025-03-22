shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float glow_intensity : hint_range(0.1, 10.0) = 0.963;

uniform float pole_outer_width : hint_range(0.0005, 0.01) = 0.001;
uniform float pole_inner_width : hint_range(0.0005, 0.05) = 0.001;
uniform float pole_height : hint_range(0.3, 0.95) = 0.745;
uniform float flag_width : hint_range(0.1, 0.6) = 0.33;
uniform float flag_height : hint_range(0.05, 0.4) = 0.2;

uniform float wave_speed : hint_range(0.1, 8.0) = 2.0;
uniform float wave_frequency : hint_range(0.5, 15.0) = 3.0;
uniform float wave_amplitude : hint_range(0.001, 0.2) = 0.076;

uniform float pulse_speed : hint_range(0.1, 5.0) = 1.2;
uniform float pulse_min : hint_range(0.1, 2.0) = 1.299;
uniform float pulse_max : hint_range(1.0, 5.0) = 2.049;

uniform float glow_radius : hint_range(0.001, 0.1) = 0.006;
uniform float outer_glow_radius : hint_range(0.005, 0.2) = 0.059;
uniform float glow_falloff : hint_range(0.5, 8.0) = 4.887;

void fragment() {
    vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0);
    vec2 uv = UV;
    float pulse = pulse_min + (pulse_max - pulse_min) * (0.5 + 0.5 * sin(TIME * pulse_speed));
    
    float pole_center_x = 0.15;
    float pole_top_y = 0.25;
    float pole_bottom_y = pole_top_y + pole_height;
    
    float flag_start_x = pole_center_x;
    float flag_top_y = pole_top_y;
    
    // POLE RENDERING
    if (uv.y >= pole_top_y && uv.y <= pole_bottom_y) {
        float left_edge_x = pole_center_x - pole_outer_width;
        float right_edge_x = pole_center_x + pole_inner_width;
        
        float left_edge_dist = abs(uv.x - left_edge_x);
        float right_edge_dist = abs(uv.x - right_edge_x);
        
        if (left_edge_dist < glow_radius || right_edge_dist < glow_radius) {
            float dist = min(left_edge_dist, right_edge_dist);
            float edge_glow = smoothstep(glow_radius, 0.0, dist);
            edge_glow = pow(edge_glow, glow_falloff);

            final_color += glow_color * edge_glow * glow_intensity * pulse;
        }
        
        if (left_edge_dist < outer_glow_radius || right_edge_dist < outer_glow_radius) {
            float dist = min(left_edge_dist, right_edge_dist);
            float outer_glow = smoothstep(outer_glow_radius, glow_radius, dist);
            outer_glow = pow(outer_glow, glow_falloff * 0.8);
            
            final_color += glow_color * outer_glow * glow_intensity * 0.5 * pulse;
        }
    }
    
    // FLAG RENDERING
    float flag_x_norm = (uv.x - flag_start_x) / flag_width;
    
    float time_val = TIME * wave_speed;
    
    float wave_factor = pow(flag_x_norm, 1.2);
    float wave = sin(flag_x_norm * wave_frequency + time_val) * wave_amplitude * wave_factor;
    
    float waved_top_y = flag_top_y + wave;
    float waved_bottom_y = flag_top_y + flag_height + wave;
    
    if (uv.x >= flag_start_x && uv.x <= flag_start_x + flag_width) {
        float top_dist = abs(uv.y - waved_top_y);
        float bottom_dist = abs(uv.y - waved_bottom_y);
        float right_dist = abs(uv.x - (flag_start_x + flag_width));
        
        float left_dist = abs(uv.x - flag_start_x);
        
        if (left_dist < glow_radius * 1.5) {
            if (uv.y >= flag_top_y - glow_radius && uv.y <= flag_top_y + flag_height + glow_radius) {
                float pole_blend = smoothstep(0.0, glow_radius * 1.5, left_dist);
                top_dist = abs(uv.y - mix(flag_top_y, waved_top_y, pole_blend));
                bottom_dist = abs(uv.y - mix(flag_top_y + flag_height, waved_bottom_y, pole_blend));
            }
        }
        
        float inner_glow_radius = glow_radius;
        if (top_dist < inner_glow_radius || bottom_dist < inner_glow_radius || 
            (right_dist < inner_glow_radius && uv.y >= waved_top_y && uv.y <= waved_bottom_y)) {
            
            float dist = min(min(top_dist, bottom_dist), 
                           (uv.y >= waved_top_y && uv.y <= waved_bottom_y) ? right_dist : 1.0);
            float edge_glow = smoothstep(inner_glow_radius, 0.0, dist);
            edge_glow = pow(edge_glow, glow_falloff);
            
            final_color += glow_color * edge_glow * glow_intensity * pulse;
        }
        
        if (top_dist < outer_glow_radius || bottom_dist < outer_glow_radius || 
            (right_dist < outer_glow_radius && uv.y >= waved_top_y && uv.y <= waved_bottom_y)) {
            
            float dist = min(min(top_dist, bottom_dist), 
                           (uv.y >= waved_top_y && uv.y <= waved_bottom_y) ? right_dist : 1.0);
            float outer_glow = smoothstep(outer_glow_radius, inner_glow_radius, dist);
            outer_glow = pow(outer_glow, glow_falloff * 0.7);
            
            final_color += glow_color * outer_glow * glow_intensity * 0.4 * pulse;
        }
    }
    
    COLOR = final_color;
}