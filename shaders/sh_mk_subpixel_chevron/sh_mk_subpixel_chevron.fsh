
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D texture;
uniform vec2  dimension;
uniform float seed;
uniform float scale;
uniform float size;
uniform float blur;
uniform float noise;
uniform float intensity;

#define TAU 6.28318530718
uniform int   ridgeUse;
uniform float ridgeCount;
uniform float ridgeIntens;

float random (in vec2 st, float seed) { return fract(sin(dot(st.xy + seed, vec2(1892.9898, 78.23453))) * 437.54123); }

float index(vec2 id) {
    return id.x;
}

float fnoise(vec2 pos, float siz, float dist) {
	float lig = smoothstep(siz - blur / 2., siz + blur / 2., dist);
	float rin = smoothstep(blur, 1. + blur, dist);
    float rnd = random(pos, seed);
    rnd = .5 + (rnd - .5) * 4.;
    lig = mix(lig, lig * rnd, noise * (1. - rin));
    
    return lig;
}

void main() {
    vec2 scs  = vec2(scale) * 2.;
    vec2 pos  = v_vTexcoord - .5;
         pos *= scs;
    
    vec2 oid = floor(pos);
    vec2 opx = fract(pos);
    if(opx.y >= .5) 
    	pos.x += (opx.y - .5) * .5;
    else
    	pos.x -= (opx.y - .5) * .5;
    
    vec2 sc = vec2(3., 2.);
    vec2 id = floor(pos * sc);
    vec2 px = pos * sc - id;
    vec2 uv = id / sc / scs + .5;
    
    float siz  = 1. - size;
    float ind  = index(id);
    int   indx = int(mod(ind, 3.));
    int   indy = int(mod(id.y, 2.));
    
	vec2  cn   = vec2(.5);
    	 if(indx == 0) cn.x = .5 + siz * .5;
    else if(indx == 1) cn.x = .5;
    else if(indx == 2) cn.x = .5 - siz * .5;
    
         if(indy == 0) cn.y = .5 + siz * .5;
    else if(indy == 1) cn.y = .5 - siz * .5;
    
    float dist = 1. - pow(pow(px.x - cn.x, 8.) + pow(px.y - cn.y, 8.), 1. / 8.) * 2.;
    float lig  = fnoise(pos, siz, dist);
    
    if(ridgeUse == 1) {
	    float ridge = smoothstep(.0, ridgeIntens, pow(abs(sin(px.x * TAU * ridgeCount)), 2.)); 
	    lig = mix(lig, lig * ridge, 1.);
    }
    
    vec3 clr = vec3(0.);
         if(indx == 0) clr.r = intensity;
    else if(indx == 1) clr.g = intensity;
    else if(indx == 2) clr.b = intensity;
    clr *= lig;
    
    vec3 baseC = texture2D( texture, uv ).rgb;
    baseC.rgb *= clr;
    
    gl_FragColor = vec4(baseC, 1.);
    
    // gl_FragColor = vec4(px, 0., 1.);
}
