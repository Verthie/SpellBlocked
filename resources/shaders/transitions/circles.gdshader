shader_type canvas_item;

uniform float progress : hint_range(0, 1);
uniform float circle_size = 40.0;
uniform bool fill = true;

void fragment() {
	float x = abs(fract(FRAGCOORD.x / circle_size) - 0.5);
	float y = abs(fract(FRAGCOORD.y / circle_size) - 0.5);
	
	if ((x * x + y * y) * 2.0 > progress) {
		if(fill) {
			discard;
		}
	} else if (!fill) {
		discard;
	}
}