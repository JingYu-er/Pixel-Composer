//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 dimension;

void main() {
	vec2 texel = 1. / dimension;
	
    vec4 c0 = texture2D( gm_BaseTexture, v_vTexcoord * 2. + vec2(     0.,      0.) );
    vec4 c1 = texture2D( gm_BaseTexture, v_vTexcoord * 2. + vec2(texel.x,      0.) );
    vec4 c2 = texture2D( gm_BaseTexture, v_vTexcoord * 2. + vec2(     0., texel.y) );
    vec4 c3 = texture2D( gm_BaseTexture, v_vTexcoord * 2. + vec2(texel.x, texel.y) );
	
	c0.rgb *= c0.a;
	c1.rgb *= c1.a;
	c2.rgb *= c2.a;
	c3.rgb *= c3.a;
	
	gl_FragColor = (c0 + c1 + c2 + c3) / 4.;
}
