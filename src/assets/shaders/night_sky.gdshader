shader_type canvas_item;

uniform float time_scale : hint_range(0.1, 5.0) = 0.3;
uniform float scale_factor : hint_range(0.01, 1000.0) = 600.0;

uniform vec4 star_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float star_density : hint_range(0.0, 1.0) = 0.03;
uniform float star_twinkle_speed : hint_range(0.0, 5.0) = 3.675;

uniform vec4 aurora_color1 : source_color = vec4(0.1, 0.5, 0.8, 1.0);
uniform vec4 aurora_color2 : source_color = vec4(0.1, 0.8, 0.4, 1.0);
uniform float aurora_speed : hint_range(0.0, 5.0) = 2.0;
uniform float aurora_intensity : hint_range(0.0, 1.0) = 0.288;
uniform float aurora_frequency : hint_range(0.0, 3.0) = 0.379;

uniform vec4 milkyway_color : source_color = vec4(0.5, 0.5, 0.8, 0.2);
uniform float milkyway_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float milkyway_scale_factor : hint_range(0.1, 10.0) = 1.0;

uniform float shooting_star_chance : hint_range(0.0, 1.0) = 1.0;
uniform float shooting_star_speed : hint_range(0.5, 10.0) = 1.31;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 3.0;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

float star_field(vec2 uv, float time) {
    float stars = 0.0;
    vec2 scaled_uv = uv * scale_factor;

    for (float i = 0.0; i < 3.0; i++) {
        vec2 p = scaled_uv * (1.0 + i * 0.4);

        float star_existence = step(1.0 - star_density * 0.7, hash(floor(p) + i * 10.0));

        float brightness = hash(floor(p) + i) * 0.8 + 0.2;
        float twinkle = sin(time * star_twinkle_speed * (hash(floor(p)) * 5.0 + 1.0)) * 0.5 + 0.5;
        brightness *= mix(0.5, 1.0, twinkle);

        vec2 star_pos = fract(p) - 0.5;
        float star_shape = 1.0 - smoothstep(0.01, 0.05 + hash(floor(p)) * 0.05, length(star_pos));

        stars += star_shape * brightness * star_existence;
    }

    return min(stars, 1.0);
}

float render_aurora_instance(float seed, vec2 uv, float time, float visibility) {
    float width = 0.3 + hash(vec2(seed, 42.0)) * 0.5;
    float height = 0.2 + hash(vec2(seed, 13.5)) * 0.2;

    vec2 center = vec2(
        hash(vec2(seed, 78.3)) * 0.8 + 0.1, // x: 0.1 to 0.9
        hash(vec2(seed, 23.7)) * 0.6 + 0.2  // y: 0.2 to 0.8
    );

    center += vec2(
        sin(time * 0.02 + seed * 10.0) * 0.05,
        cos(time * 0.015 + seed * 15.0) * 0.05
    );

    float dist_x = (uv.x - center.x) / width;
    float dist_y = (uv.y - center.y) / height;

    float mask = exp(-dist_x * dist_x * 8.0) * exp(-dist_y * dist_y * 12.0);

    float aurora_pattern_scale = 5.0;

    vec2 wave_uv = (uv - center) * aurora_pattern_scale;
    wave_uv.y += time * aurora_speed * 0.1;

    float waves = fbm(wave_uv * 6.0, 3) * 1.5;

    float frequency = aurora_frequency * (1.0 + hash(vec2(seed, 89.7)) * 0.5);
    float bands = sin((dist_y * 5.0 + time * 0.2 + waves * 0.5) * frequency * 3.14159);
    bands = pow(abs(bands), 0.5) * mask;

    return bands * aurora_intensity * visibility;
}

float aurora(vec2 uv, float time) {
    float cycle_time = 20.0;
    float transition_time = 8.0;

    float cycle_position = fract(time / cycle_time);

    float current_seed = floor(time / cycle_time);
    float next_seed = current_seed + 1.0;

    float crossfade = smoothstep(0.0, transition_time / cycle_time, cycle_position);
    if (cycle_position > (1.0 - transition_time / cycle_time)) {
        crossfade = smoothstep(0.0, transition_time / cycle_time, cycle_position - (1.0 - transition_time / cycle_time));
        crossfade = 1.0 - crossfade;
    }

    float current_visible = step(0.3, hash(vec2(current_seed, 123.45)));
    float next_visible = step(0.3, hash(vec2(next_seed, 123.45)));

    float current = render_aurora_instance(current_seed, uv, time, current_visible);
    float next = render_aurora_instance(next_seed, uv, time, next_visible);

    return mix(current, next, crossfade);
}

float render_milkyway_instance(float seed, vec2 uv, float time) {
    float angle = hash(vec2(seed, 42.0)) * 3.14159;

    vec2 center = vec2(
        0.5 + (hash(vec2(seed, 78.3)) - 0.5) * 0.8,
        0.5 + (hash(vec2(seed, 23.7)) - 0.5) * 0.8
    );

    center += vec2(
        sin(time * 0.015 + seed * 10.0) * 0.05,
        cos(time * 0.01 + seed * 15.0) * 0.05
    );

    float adjusted_scale = 3.0 + 7.0 * (1.0 - pow(min(scale_factor, 600.0) / 600.0, 0.5));
    adjusted_scale *= milkyway_scale_factor;

    vec2 p = (uv - center) * adjusted_scale;
    vec2 rotated = vec2(
        p.x * cos(angle) - p.y * sin(angle),
        p.x * sin(angle) + p.y * cos(angle)
    );

    float width_factor = 0.5 / sqrt(milkyway_scale_factor);
    float width = (0.1 + hash(vec2(seed, 91.3)) * 0.2) * width_factor;

    float band = exp(-pow(rotated.y / width, 2.0) * 6.0);

    float noise_scale = 0.5 * milkyway_scale_factor;
    vec2 noise_pos = rotated * noise_scale + time * 0.02;
    float nebula = fbm(noise_pos, 4);

    float clusters = 0.0;
    for (int i = 0; i < 3; i++) {
        float cluster_seed = seed + float(i) * 10.0;
        vec2 cluster_pos = vec2(
            hash(vec2(cluster_seed, 45.2)) * 2.0 - 1.0,
            (hash(vec2(cluster_seed, 67.8)) - 0.5) * width * 4.0
        );

        float cluster_scale = 1.0 / sqrt(milkyway_scale_factor);
        float dist = length((rotated - cluster_pos) * vec2(0.5, 2.0) * cluster_scale);
        clusters += smoothstep(0.3, 0.0, dist) * 0.5;
    }

    return (band * nebula + clusters);
}

float milkyway(vec2 uv, float time) {
    float cycle_time = 30.0;
    float transition_time = 10.0;

    float cycle_position = fract(time / cycle_time);

    float current_seed = floor(time / cycle_time);
    float next_seed = current_seed + 1.0;

    float crossfade = smoothstep(0.0, transition_time / cycle_time, cycle_position);
    if (cycle_position > (1.0 - transition_time / cycle_time)) {
        crossfade = smoothstep(0.0, transition_time / cycle_time, cycle_position - (1.0 - transition_time / cycle_time));
        crossfade = 1.0 - crossfade;
    }

    float current = render_milkyway_instance(current_seed, uv, time);
    float next = render_milkyway_instance(next_seed, uv, time);
    float result = mix(current, next, crossfade);

    return result * milkyway_intensity;
}

float shooting_star(vec2 uv, float time) {
    float starTime = fract(time * 0.2);
    float show_star = 0.0;

    for (int i = 0; i < 3; i++) {
        float seed = float(i) * 42.1234;

        vec2 star_origin = vec2(
            hash(vec2(seed, 78.233 + floor(time * 0.1))),
            hash(vec2(43.742 + floor(time * 0.1), seed)) * 0.8 + 0.1
        );

        float star_cycle = fract(time * 0.05 + hash(star_origin + float(i)));
        float star_active = step(1.0 - shooting_star_chance * 0.3, hash(star_origin + time * 0.1)) *
                           step(star_cycle, 0.2);

        if (star_active > 0.0) {
            float angle = hash(star_origin + 34.5) * 3.14159 * 0.5;
            vec2 dir = normalize(vec2(
                sin(angle),
                cos(angle)
            ));

            float progress = fract(star_cycle / 0.2) * shooting_star_speed;
            vec2 star_pos = star_origin + dir * progress;

            float trail_length = 0.1 + hash(star_origin) * 0.1;
            vec2 to_star = uv - star_pos;
            float along_trail = dot(to_star, -dir);
            float dist_from_trail = length(to_star - (-dir) * along_trail);

            float width = 0.003 / sqrt(min(scale_factor, 600.0) / 50.0);
            float trail = smoothstep(width, 0.0, dist_from_trail) *
                         smoothstep(0.0, trail_length, along_trail) *
                         smoothstep(trail_length * 1.1, 0.0, along_trail);

            show_star = max(show_star, trail * 2.0);
        }
    }

    return show_star;
}

void fragment() {
    float time = TIME * time_scale;
    vec2 uv = UV;

    float stars = star_field(uv, time);

    float mw = milkyway(uv, time);
    vec4 mw_color = milkyway_color * mw;

    float aur = aurora(uv, time);

    vec4 aurora_blend = mix(aurora_color1, aurora_color2, sin(uv.x * 3.14159 + time * 0.1) * 0.5 + 0.5);
    vec4 aur_color = aurora_blend * aur;

    float shooting = shooting_star(uv, time);

    vec4 final_color = vec4(0.0, 0.0, 0.05, 1.0);

    final_color.rgb += star_color.rgb * stars;
    final_color.rgb += mw_color.rgb;
    final_color.rgb += aur_color.rgb;
    final_color.rgb += vec3(1.0) * shooting;

    COLOR = final_color;
}