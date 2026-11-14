shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_resolution : hint_range(64.0, 512.0, 1.0) = 140.0;

void fragment() {
	// Toma el centro exacto de cada bloque para no desplazar ni alterar los colores
	vec2 grid_uv = (floor(SCREEN_UV * pixel_resolution) + 0.5) / pixel_resolution;
	COLOR = texture(screen_texture, grid_uv);
}