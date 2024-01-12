//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

#define c30     (1.0 / 0.86602540378)
#define PI      3.14159265359
#define GRADIENT_LIMIT 128

uniform vec2  position;
uniform vec2  dimension;
uniform float seed;
uniform int   mode;
uniform int   aa;

uniform vec2      scale;
uniform int       scaleUseSurf;
uniform sampler2D scaleSurf;

uniform vec2      angle;
uniform int       angleUseSurf;
uniform sampler2D angleSurf;

uniform vec2      width;
uniform int       widthUseSurf;
uniform sampler2D widthSurf;

uniform vec4  gapCol;
uniform int   gradient_use;
uniform int   gradient_blend;
uniform vec4  gradient_color[GRADIENT_LIMIT];
uniform float gradient_time[GRADIENT_LIMIT];
uniform int   gradient_keys;

uniform int   textureTruchet;
uniform float truchetSeed;
uniform float truchetThres;

float random (in vec2 st) { return fract(sin(dot(st.xy + vec2(85.456034, 64.54065), vec2(12.9898, 78.233))) * (43758.5453123 + seed) ); }

vec3 rgb2hsv(vec3 c) { #region
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 0.0000000001;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
} #endregion

vec3 hsv2rgb(vec3 c) { #region
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
} #endregion

float hueDist(float a0, float a1, float t) { #region
	float da = fract(a1 - a0);
    float ds = fract(2. * da) - da;
    return a0 + ds * t;
} #endregion

vec3 hsvMix(vec3 c1, vec3 c2, float t) { #region
	vec3 h1 = rgb2hsv(c1);
	vec3 h2 = rgb2hsv(c2);
	
	vec3 h = vec3(0.);
	h.x = h.x + hueDist(h1.x, h2.x, t);
	h.y = mix(h1.y, h2.y, t);
	h.z = mix(h1.z, h2.z, t);
	
	return hsv2rgb(h);
} #endregion

vec4 gradientEval(in float prog) { #region
	vec4 col = vec4(0.);
	
	for(int i = 0; i < GRADIENT_LIMIT; i++) {
		if(gradient_time[i] == prog) {
			col = gradient_color[i];
			break;
		} else if(gradient_time[i] > prog) {
			if(i == 0) 
				col = gradient_color[i];
			else {
				float t = (prog - gradient_time[i - 1]) / (gradient_time[i] - gradient_time[i - 1]);
				if(gradient_blend == 0)
					col = mix(gradient_color[i - 1], gradient_color[i], t);
				else if(gradient_blend == 1)
					col = gradient_color[i - 1];
				else if(gradient_blend == 2)
					col = vec4(hsvMix(gradient_color[i - 1].rgb, gradient_color[i].rgb, t), 1.);
			}
			break;
		}
		if(i >= gradient_keys - 1) {
			col = gradient_color[gradient_keys - 1];
			break;
		}
	}
	
	return col;
} #endregion

vec3 triGrid(vec2 p){ #region
    float _stx = (p.x + c30 / 2.0 * p.y);
    float stx  = abs(fract(_stx) - 0.5);
   	
    float _sty = (p.x - c30 / 2.0 * p.y);
    float sty  = abs(fract(_sty) - 0.5);
    float sth  = abs(fract(p.y * c30) - 0.5);
    float sm   = 1.;
    
	float n = min(smoothstep(sm, -sm, stx), 
				min(smoothstep(sm, -sm, sty), smoothstep(sm, -sm, sth))
			  );
	n = (n - .16) / (.35 - .16);
	
    return vec3((floor(_stx) + floor(_sty) + 1.) / 2., floor(p.y * c30), n);
} #endregion

void main() { #region
	#region params
		vec2 sca = scale;
		if(scaleUseSurf == 1) {
			vec4 _vMap = texture2D( scaleSurf, v_vTexcoord );
			sca = vec2(mix(scale.x, scale.y, (_vMap.r + _vMap.g + _vMap.b) / 3.));
		}
		
		float ang = angle.x;
		if(angleUseSurf == 1) {
			vec4 _vMap = texture2D( angleSurf, v_vTexcoord );
			ang = mix(angle.x, angle.y, (_vMap.r + _vMap.g + _vMap.b) / 3.);
		}
		ang = radians(ang);
		
		float wid = width.x;
		if(widthUseSurf == 1) {
			vec4 _vMap = texture2D( widthSurf, v_vTexcoord );
			wid = mix(width.x, width.y, (_vMap.r + _vMap.g + _vMap.b) / 3.);
		}
	#endregion
	
    vec2 pos = (v_vTexcoord - position) * sca, _pos;
	float ratio = dimension.x / dimension.y;
	_pos.x = pos.x * ratio * cos(ang) - pos.y * sin(ang);
	_pos.y = pos.x * ratio * sin(ang) + pos.y * cos(ang);
	
	vec3  tri   = triGrid(_pos);
	float dist  = max(0., tri.z);
	vec4 colr;
	
	if(mode == 1) {
		gl_FragColor = vec4(vec3(dist), 1.);
		return;
	}
	
	if(mode == 0) {
		vec2 uv = fract(tri.xy / sca);
		colr = gradientEval(random(uv));
	} else if(mode == 2) {
		vec2 uv = fract((_pos * vec2(1., c30) - tri.xy) + vec2(0.5, 0.));
		
		if(textureTruchet == 1) {
			float rx  = random(floor(tri.xy) + truchetSeed / 100.);
			float ry  = random(floor(tri.xy) + truchetSeed / 100. + vec2(0.4864, 0.6879));
			float ang = 0.;
			if(rx > truchetThres) ang += 120.;
			if(ry > truchetThres) ang += 120.;
			ang = radians(ang);
			
			uv = 0.5 + mat2(cos(ang), -sin(ang), sin(ang), cos(ang)) * (uv - 0.5);
		}
		
		colr = texture2D( gm_BaseTexture, uv );
	} else if(mode == 3) {
		vec2 uv = clamp(tri.xy / sca, 0., 1.);
		colr = texture2D( gm_BaseTexture, uv );
	}
	
	float _aa = 3. / max(dimension.x, dimension.y);
	gl_FragColor = mix(gapCol, colr, aa == 1? smoothstep(wid * 2. - _aa, wid * 2., dist) : step(wid * 2., dist));
} #endregion