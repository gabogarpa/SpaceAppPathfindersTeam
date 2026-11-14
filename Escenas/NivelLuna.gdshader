shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.01, 0.01, 0.03); // Azul/negro espacial
uniform float star_density : hint_range(10.0, 600.0) = 600.0;
uniform float star_threshold : hint_range(0.75, 0.8) = 0.78;

float hash(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 dir = EYEDIR;
	// Cuadrícula esférica para posicionar estrellas fijas
	vec3 grid = floor(dir * star_density);
	float star_val = hash(grid);
	
	float star = 0.0;
	if (star_val > star_threshold) {
		// Brillo variado por estrella
		star = pow((star_val - star_threshold) / (1.0 - star_threshold), 2.0);
	}
	
	COLOR = sky_color + vec3(star);
}