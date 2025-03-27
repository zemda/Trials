shader_type canvas_item;

uniform float scroll_speed : hint_range(0.0, 2.0) = 0.1;
uniform float depth_effect : hint_range(0.0, 5.0) = 1.0;


float something(vec2 uv, vec2 position, float size) {
    uv = (uv - position) / size;
    float f = 0.0;
    f += smoothstep(0.1, 0.0, abs(uv.x - 0.2));
    
    if (uv.y > 0.1 && uv.y < 0.3) {
        f += smoothstep(0.1, 0.0, abs(uv.x - 0.5)) * smoothstep(0.3, 0.1, abs(uv.y - 0.2));
    }
    
    if (uv.y > -0.2 && uv.y < 0.0) {
        f += smoothstep(0.1, 0.0, abs(uv.x - 0.4)) * smoothstep(0.2, 0.0, abs(uv.y - -0.1));
    }
    
    return clamp(f, 0.0, 1.0);
}

void fragment() {
    vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
    
    for (float i = 0.0; i < 4.0; i++) {
        float depth = 0.5 + i * 0.5;
        float size = 0.3 / depth;
        float opacity = 0.15 / depth;
        
        float speed = scroll_speed * depth_effect / depth;
        float time_offset = TIME * speed;
        
        for (float x = 0.0; x < 3.0; x++) {
            for (float y = 0.0; y < 4.0; y++) {
                vec2 position = vec2(
                    mod(0.3 + x * 0.5 - time_offset * 0.5, 2.0) - 0.5,
                    mod(0.2 + y * 0.5 - time_offset * 0.2, 2.0) - 0.5
                );
                
                float f_shape = something(UV, position, size);
                color += vec4(vec3(1.0), f_shape * opacity);
            }
        }
    }
    
    COLOR = color;
}