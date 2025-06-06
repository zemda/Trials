// https://godotshaders.com/shader/electric-ball-canvas-item/
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D noise : repeat_enable; 
uniform sampler2D noise2 : repeat_enable;  
uniform float brightness = 5.0;
uniform float time_scale = 1.0;
uniform float electric_intensity = 1.0;

void fragment() {
	vec2 cc_uv = UV - vec2(.5); 
	float angle = atan(cc_uv.y, cc_uv.x) / PI + 1.;
	float p = sqrt(dot(cc_uv, cc_uv)); 
	vec2 puv = vec2(p, angle * .5);
	vec2 uv = puv * 2.;
	float time = TIME * time_scale;
	vec4 old_colo = COLOR;
	COLOR = vec4(.0);
	
	int iterations = int(min(max(electric_intensity, 1.0), 10.0));
	float intensity_scale = 0.07 * (5.0 / float(iterations));
	
	for(int i = 1; i <= 10; i++){
		if (i > iterations) break;
		
		float intensive = 0.1 + intensity_scale * float(i);
		vec2 offset = (texture(noise, vec2(time*.35*(.5+fract(sin(float(i)*55.))), angle)).rg - vec2(.5)) * intensive; 
		vec2 uuv = uv + offset;
		float dist = abs(uuv.x - .5);
		float rand_speed = .2 + .05 * fract(cos(float(i)*1144.));
		float gone = smoothstep(.1 + 0.05 * (float(i) - .5), 1.0, texture(noise2, uv + vec2(time*rand_speed)).r);
		COLOR += gone * old_colo / dist * (.01 * (5.0 / float(iterations))) * texture(noise2, uuv + vec2(time)).r;
	}
	vec4 light = old_colo * smoothstep(1.0, -2.0, abs(uv.x - .5) * 2.0) * texture(noise2, uv).a; 
	COLOR += light * brightness;
}