shader_type canvas_item;

uniform float offset = 1.0;
uniform float slope = 10.0;
uniform float speed = 30;
uniform float direction = 1.0;

const float pixel_size = 1.0/3.0;

float align_to_pixel(float v){
	return float(int(v/pixel_size))*pixel_size;
}

void vertex() {
	float x = offset * pixel_size + 0.1;
	// Called for every vertex the material is visible on.
	VERTEX.x += align_to_pixel(x * sin((slope*UV.y) + (speed * TIME))) * direction;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
