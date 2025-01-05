shader_type canvas_item;

uniform float progress : hint_range( 0.0, 1.0, 0.01 ) = 0.0;
uniform float rectangle_height : hint_range(8.0, 100.0, 2.0) = 40.0;
uniform float rectangle_width : hint_range(8.0, 100.0, 2.0) = 40.0;
uniform bool fill = true;
uniform bool rectangle_skew = false;
uniform float skew_y_value : hint_range(-50.0, 50.0, 0.1) = 5.0;

float get_line( float uv )
{
	uv = mod( uv, 1.0 );
	return round( ( min( uv, 1.0 - uv ) / ( progress )) );
}

void fragment()
{
	float x = fract((FRAGCOORD.x / rectangle_width) - 0.5);
	float y = fract((FRAGCOORD.y / rectangle_height) - 0.5);
	float skew_allower = rectangle_skew == true ? 1.0 : 0.0;
	

	if ((get_line(x) * get_line(y + (skew_allower * skew_y_value))) > progress) {
	//if ((get_line(x) * get_line(y)) > progress) {
		if (fill) {
			discard;
		}
	} else if (!fill){	
		discard;
	}
}