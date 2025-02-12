shader_type canvas_item;

uniform float progress : hint_range(0, 1);
uniform float diamond_size = 50.0;
uniform float curve_amount: hint_range(-20.0, 50.0, 0.1) = 0.0;
uniform bool fill = true;
uniform bool sweep_x = true;
uniform bool sweep_y = false;
uniform float sweep_x_value : hint_range(-1.0, 1.0, 0.1) = 1.0;
uniform float sweep_y_value : hint_range(-1.0, 1.0, 0.1) = 1.0;

void fragment() {
	float x = abs(fract(FRAGCOORD.x / diamond_size) - 0.5);
	float y = abs(fract(FRAGCOORD.y / diamond_size) - 0.5);

	float x_sweep_allower = sweep_x == true ? 1.0 : 0.0;
	float y_sweep_allower = sweep_y == true ? 1.0 : 0.0;

	float x_adder = sweep_x_value < 0.0 ? 1.0 : 0.0;
	float y_adder = sweep_y_value < 0.0 ? 1.0 : 0.0;


	//if ((x + y - x + y) > progress) { żaluzje
	//if (x + y + (UV.x * x_sweep_allower) + (UV.y * y_sweep_allower) > progress * (1.0 + x_sweep_allower + y_sweep_allower)) {

		float calculation_left = (x + (y * x * curve_amount) + y) + (UV.x * x_sweep_allower * sweep_x_value + x_adder) + (UV.y * y_sweep_allower * sweep_y_value + y_adder);
		float calculation_right = (1.0 + x_sweep_allower + y_sweep_allower) + abs(0.25 * curve_amount);

	if (curve_amount < 0.0) {
		calculation_left += abs(0.25 * curve_amount);
	}

	if (calculation_left > progress * calculation_right) {
		if(fill) {
			discard;
		}
	} else if (!fill) {
		discard;
	}
}