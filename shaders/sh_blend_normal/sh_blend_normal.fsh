//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 dimension;
uniform int tile_type;

uniform int useMask;
uniform int preserveAlpha;
uniform sampler2D mask;
uniform sampler2D fore;
uniform float opacity;

float sampleMask() {
	if(useMask == 0) return 1.;
	vec4 m = texture2D( mask, v_vTexcoord );
	return (m.r + m.g + m.b) / 3. * m.a;
}

void main() {
	vec4 _col1 = texture2D( gm_BaseTexture, v_vTexcoord );
	
	vec2 fore_tex = v_vTexcoord;
	if(tile_type == 0) {
		fore_tex = v_vTexcoord;
	} else if(tile_type == 1) {
		fore_tex = fract(v_vTexcoord * dimension);
	}
	
	vec4 _col0 = texture2D( fore, fore_tex );
	_col0.a *= opacity * sampleMask();
	
	float al = _col0.a + _col1.a * (1. - _col0.a);
	vec4 res = ((_col0 * _col0.a) + (_col1 * _col1.a * (1. - _col0.a))) / al;
	res.a = al;
	if(preserveAlpha == 1) res.a = _col1.a;
	
    gl_FragColor = res;
}
