shader_type canvas_item;

uniform vec4 color : source_color;
uniform vec4 background_color : source_color;
uniform float checker_size = 20.0;
uniform float time_scale = 10.0;
uniform float alpha = 0.9;

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    float circle_mask = step(dist, 0.5);
    
    vec2 pos = UV * checker_size;
    
    float time_value = TIME * time_scale;
    
    pos.x += time_value * 0.1;
    pos.y += time_value * 0.1;
    
    vec2 grid = floor(pos);
    float checker = mod(grid.x + grid.y, 2.0);
    
    vec4 final_color = mix(background_color, color, checker);
    
    final_color.a *= circle_mask * alpha;
    
    COLOR = final_color;
}