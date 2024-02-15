//
// Simple passthrough fragment shader
//
varying vec2  v_vTexcoord;
varying vec4  v_vColour;
uniform int   invert;
uniform int   distMode;
uniform int   swap;

uniform vec2      blend;
uniform int       blendUseSurf;
uniform sampler2D blendSurf;

#region /////////////// SAMPLING ///////////////

const   float PI = 3.14159265358979323846;
uniform int   interpolation;
uniform vec2  sampleDimension;

const int RSIN_RADIUS = 1;

float sinc ( float x ) { return x == 0.? 1. : sin(x * PI) / (x * PI); }

vec4 texture2D_rsin( sampler2D texture, vec2 uv ) {
    vec2 tx = 1.0 / sampleDimension;
    vec2 p  = uv * sampleDimension - vec2(0.5);
    
	vec4 sum = vec4(0.0);
    float weights = 0.;
    
    for (int x = -RSIN_RADIUS; x <= RSIN_RADIUS; x++)
	for (int y = -RSIN_RADIUS; y <= RSIN_RADIUS; y++) {
        float a = length(vec2(float(x), float(y))) / float(RSIN_RADIUS);
		if(a > 1.) continue;
        float w = sinc(a * PI * tx.x) * sinc(a * PI * tx.y);
        vec2 offset = vec2(float(x), float(y)) * tx;
        vec4 sample = texture2D(texture, (p + offset + vec2(0.5)) / sampleDimension);
        sum += w * sample;
        weights += w;
    }
	
    return sum / weights;
}

vec4 texture2D_bicubic( sampler2D texture, vec2 uv ) {
	uv = uv * sampleDimension + 0.5;
	vec2 iuv = floor( uv );
	vec2 fuv = fract( uv );
	uv = iuv + fuv * fuv * (3.0 - 2.0 * fuv);
	uv = (uv - 0.5) / sampleDimension;
	return texture2D( texture, uv );
}

vec4 texture2Dintp( sampler2D texture, vec2 uv ) {
	if(interpolation == 2)		return texture2D_bicubic( texture, uv );
	else if(interpolation == 3)	return texture2D_rsin( texture, uv );
	return texture2D( texture, uv );
}

#endregion /////////////// SAMPLING ///////////////

void main() {
	vec2 center = vec2(0.5, 0.5);
	vec2 coord;
	
	float bld = blend.x;
	if(blendUseSurf == 1) {
		vec4 _vMap = texture2Dintp( blendSurf, v_vTexcoord );
		bld = mix(blend.x, blend.y, (_vMap.r + _vMap.g + _vMap.b) / 3.);
	}
	
	if(invert == 0) {
		float dist = distance(v_vTexcoord, center) / (sqrt(2.) * .5);
		if(distMode == 1)      dist = sqrt(dist);
		else if(distMode == 2) dist = log(dist);
		
		vec2  cenPos = v_vTexcoord - center;
		float angle	 = (atan(cenPos.y, cenPos.x) / PI + 1.) / 2.;
		
		coord = fract(vec2(dist, angle));
	} else if(invert == 1) {
		float dist = v_vTexcoord.x * 0.5;
		if(distMode == 1)      dist = sqrt(dist);
		else if(distMode == 2) dist = log(dist);
		
		float ang  = v_vTexcoord.y * PI * 2.;
		
		coord = fract(center + vec2(cos(ang), sin(ang)) * dist);
	}
	
	if(swap == 1) coord.xy = coord.yx;
	gl_FragColor = texture2Dintp( gm_BaseTexture, mix(v_vTexcoord, coord, bld) );
}
