extends Node3D

func _ready() -> void:
	# Crea el shader mate definitivo con sombras suaves y colores puros
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode diffuse_lambert, specular_disabled, ambient_light_disabled;
	
	uniform sampler2D tex : source_color, filter_nearest;
	
	void fragment() {
		// Lee los colores de tu paleta .png
		ALBEDO = texture(tex, UV).rgb;
		
		// TIP: Si algún terreno como Marte se ve de un solo color, comenta 
		// la línea de arriba y descomenta esta de abajo para usar Vertex Colors:
		// ALBEDO = COLOR.rgb;
	}
	
	void light() {
		// Mantiene las caras en sombra al 85% de su brillo original para suavizarlas
		float luz = max(dot(NORMAL, LIGHT), 0.85); 
		
		// No usa LIGHT_COLOR para evitar que el sol tiña los colores de MagicaVoxel
		DIFFUSE_LIGHT += ALBEDO * luz * ATTENUATION; 
	}
	"""
	
	# Recorre todos los MeshInstance3D que existan dentro del nivel
	for nodo in find_children("*", "MeshInstance3D", true, false):
		# Ignora el modelo de MoonBot y de los Resortes
		if "MoonBot" in nodo.get_path().get_concatenated_names() or "Resorte" in nodo.get_path().get_concatenated_names():
			continue
			
		_quitar_brillo_a_malla(nodo, shader)

func _quitar_brillo_a_malla(malla: MeshInstance3D, shader: Shader) -> void:
	if not malla.mesh:
		return
		
	# Recorre todas las superficies del bloque por si tiene más de un material
	for i in range(malla.mesh.get_surface_count()):
		var mat_original = malla.mesh.surface_get_material(i)
		if not mat_original:
			mat_original = malla.get_active_material(i)
			
		if mat_original is BaseMaterial3D and mat_original.albedo_texture:
			var mat_mate = ShaderMaterial.new()
			mat_mate.shader = shader
			mat_mate.set_shader_parameter("tex", mat_original.albedo_texture)
			malla.set_surface_override_material(i, mat_mate)
