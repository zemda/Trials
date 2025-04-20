shader_type canvas_item;

/** Night‑Sky (rev‑4)
 *  · milkyway_intensity now truly scales brightness (outside the function)
 *  · Milky Way drifts slowly and re‑rolls its random tilt every 30 s → looks new each play‑through
 *  · Aurora unchanged from rev‑3
 *  · Added optional sky_seed uniform if you want to set randomness from GDScript
 */

// ---------- USER‑TUNABLE UNIFORMS ---------------
uniform float time_scale           : hint_range(0.1, 5.0) = 0.3;
uniform float scale_factor         : hint_range(0.01, 1000.0) = 600.0;

uniform vec4  star_color           : source_color = vec4(1.0);
uniform float star_density         : hint_range(0.0, 1.0) = 0.03;
uniform float star_twinkle_speed   : hint_range(0.0, 5.0) = 3.675;

// Aurora
uniform vec4  aurora_color1        : source_color = vec4(0.05, 0.45, 0.8, 1.0);
uniform vec4  aurora_color2        : source_color = vec4(0.05, 0.8, 0.3, 1.0);
uniform float aurora_intensity     : hint_range(0.0, 4.0) = 1.4;
uniform float aurora_band_width    : hint_range(0.02, 0.6) = 0.22;   // ribbon half‑width
uniform float aurora_ribbon_sharp  : hint_range(0.5, 15.0) = 9.0;

// Milky Way
uniform vec4  milkyway_color       : source_color = vec4(0.60, 0.60, 0.90, 0.25);
uniform float milkyway_intensity   : hint_range(0.0, 4.0) = 1.6;
uniform float milkyway_band_width  : hint_range(0.05, 0.8) = 0.14;   // thickness of central stripe

// Optional seed so you can randomise from script (e.g. sky_seed = randi())
uniform float sky_seed = 0.0;

// Shooting star
uniform float shooting_star_chance : hint_range(0.0, 1.0) = 1.0;
uniform float shooting_star_speed  : hint_range(0.5, 10.0) = 1.31;

//-------------------------------------------------
// Utility noise ----------------------------------
float hash(vec2 p){
    p = fract(p*vec2(123.34,456.21));
    p += dot(p,p+45.32);
    return fract(p.x*p.y);
}

float noise(vec2 p){
    vec2 i=floor(p);
    vec2 f=fract(p);
    vec2 u=f*f*(3.0-2.0*f);
    float a=hash(i);
    float b=hash(i+vec2(1.0,0.0));
    float c=hash(i+vec2(0.0,1.0));
    float d=hash(i+vec2(1.0,1.0));
    return mix(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y;
}

float fbm(vec2 p,int oct){
    float v=0.0; float a=0.5; float f=1.0;
    for(int i=0;i<oct;i++){ v+=a*noise(p*f); f*=2.0; a*=0.5; }
    return v;
}

//-------------------------------------------------
// Stars ------------------------------------------
float star_field(vec2 uv,float t){
    float stars=0.0; vec2 suv=uv*scale_factor;
    for(float i=0.0;i<3.0;i++){
        vec2 p=suv*(1.0+i*0.4);
        float exist=step(1.0-star_density*0.7,hash(floor(p)+i*10.0));
        float bright=hash(floor(p)+i)*0.8+0.2;
        float twi=sin(t*star_twinkle_speed*(hash(floor(p))*5.0+1.0))*0.5+0.5;
        bright*=mix(0.5,1.0,twi);
        vec2 pos=fract(p)-0.5;
        float shape=1.0-smoothstep(0.01,0.05+hash(floor(p))*0.05,length(pos));
        stars+=shape*bright*exist;
    }
    return clamp(stars,0.0,1.0);
}

//-------------------------------------------------
// Aurora (same as rev‑3) --------------------------
float aurora(vec2 uv, float t){
    float acc=0.0; const int RIBBONS=4;
    float cycle=floor(t*0.05+sky_seed);      // seed offsets cycle so different per run if you set sky_seed
    for(int i=0;i<RIBBONS;i++){
        float seed=float(i)+cycle*10.0+sky_seed*0.77;
        vec2 centre=vec2(hash(vec2(seed,1.7)), hash(vec2(seed,9.3))*0.9+0.05);
        float disp=fbm(uv*4.0+vec2(0.0,t*0.2+seed),3)*0.15;
        float band=abs(uv.y-centre.y-disp);
        float core=smoothstep(aurora_band_width,0.0,band*aurora_ribbon_sharp);
        float stripes=fbm(vec2(uv.x*25.0+seed, uv.y*80.0), 2);
        acc+=core*(0.7+0.3*stripes);
    }
    return clamp(acc,0.0,1.0)*aurora_intensity;
}

//-------------------------------------------------
// Milky Way (drifting, random orientation) -------
float milkyway(vec2 uv,float t){
    // Choose a new random rotation every 30 seconds (or on new run if sky_seed differs)
    float segment=floor((t+sky_seed)*0.0333333);   // 30‑second segments
    float angleSeed=hash(vec2(segment,12.34));
    float ang=mix(-0.6,0.6, angleSeed);            // random diagonal

    vec2 c=uv-0.5;
    // slow horizontal drift to give the impression of movement
    c.x+=t*0.005;

    vec2 p=vec2(c.x*cos(ang)-c.y*sin(ang), c.x*sin(ang)+c.y*cos(ang));

    // central luminous band
    float band=exp(-pow(p.y/milkyway_band_width,2.0));
    // drifting dust clouds
    float dust=fbm(p*5.5+vec2(0.0,t*0.04),4);
    // bright clusters
    float clusters=pow(fbm(p*20.0+vec2(37.0+angleSeed*50.0),4),4.0);

    float result=band*(0.6+0.4*dust)+clusters;
    return result;   // intensity applied outside now
}

//-------------------------------------------------
// Shooting star (unchanged) ----------------------
float shooting_star(vec2 uv,float time){
    float show=0.0;
    for(int i=0;i<3;i++){
        float seed=float(i)*42.1234+sky_seed*1.3;
        vec2 origin=vec2(hash(vec2(seed,78.233+floor(time*0.1))),
                         hash(vec2(43.742+floor(time*0.1),seed))*0.8+0.1);
        float cycle=fract(time*0.05+hash(origin+float(i)));
        float active=step(1.0-shooting_star_chance,hash(origin+time*0.1))*step(cycle,0.2);
        if(active>0.0){
            float angle=hash(origin+34.5)*1.5708;
            vec2 dir=normalize(vec2(sin(angle),cos(angle)));
            float progress=fract(cycle/0.2)*shooting_star_speed;
            vec2 pos=origin+dir*progress;
            float len=0.1+hash(origin)*0.1;
            vec2 to=uv-pos;
            float along=dot(to,-dir);
            float dist=length(to-(-dir)*along);
            float width=0.003/sqrt(min(scale_factor,600.0)/50.0);
            float trail=smoothstep(width,0.0,dist)*smoothstep(0.0,len,along)*smoothstep(len*1.1,0.0,along);
            show=max(show,trail*2.0);
        }
    }
    return show;
}

//-------------------------------------------------
// Fragment ---------------------------------------
void fragment(){
    float t=TIME*time_scale;
    vec2 uv=UV;

    float stars = star_field(uv,t);
    float aur   = aurora(uv,t);
    float mwRaw = milkyway(uv,t);
    float shoot = shooting_star(uv,t);

    vec4 col=vec4(0.0,0.0,0.05,1.0);
    col.rgb += star_color.rgb * stars;

    float blend=fbm(uv*15.0+t*0.2,3)*0.5+0.5;
    col.rgb += mix(aurora_color1.rgb, aurora_color2.rgb, blend) * aur;

    // milkyway_intensity now multiplies here, so the slider has visible impact
    col.rgb += milkyway_color.rgb * mwRaw * milkyway_intensity;

    col.rgb += vec3(1.0) * shoot;

    COLOR = col;
}
