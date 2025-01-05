shader_type canvas_item;

// progress parameter is used in order to animate the shader, it controls the "progress" of the shader
uniform float progress : hint_range(0, 1); // values between 0 and 1, because UV is also between 0 and 1
uniform bool fill = true;

void fragment() {
	// UV gives the normalized screen coordinates of the current pixel (between 0 and 1)
	// UV(0,0) is top left of the screen, UV(1,1) is bottom right of the screen
	if (UV.x > progress) {
		if (fill) {
			discard; // tells the shader to not render this pixel
		}
	} else if (!fill) {
		discard;
	}
}