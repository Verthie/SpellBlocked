shader_type canvas_item;

uniform float lod: hint_range(0.0, 5.0) = 0.0; // strength of the blur
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float progress: hint_range(0.0, 1.0) = 0.6;

void fragment(){
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
	color = mix(color, vec4(0,0,0,1), progress);
	COLOR = color;
}