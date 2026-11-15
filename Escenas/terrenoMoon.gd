extends Node3D

func _ready() -> void:
	# 1. Llamamos al fade in nada más arrancar el nivel (sin await para no pausar el shader)
	_crear_fade_in(1.5)
	
	# 2. Crea un único shader mate compartido en memoria para optimizar rendimiento
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode diffuse_lambert, specular_disabled, ambient_light_disabled;
	
	uniform sampler2D tex : source_color, filter_nearest;
	
	void fragment() {
		ALBEDO = texture(tex, UV).rgb;
	}
	
	void light() {
		float luz = max(dot(NORMAL, LIGHT), 0.35);
		DIFFUSE_LIGHT += ALBEDO * luz * ATTENUATION * LIGHT_COLOR;
	}
	"""
	
	# 3. Recorre todos los MeshInstance3D que existan dentro del nivel
	for nodo in find_children("*", "MeshInstance3D", true, false):
		# Ignora el modelo de MoonBot y de los Resortes para afectar solo al terreno
		if "MoonBot" in nodo.get_path().get_concatenated_names() or "Resorte" in nodo.get_path().get_concatenated_names():
			continue
			
		_quitar_brillo_a_malla(nodo, shader)


func _quitar_brillo_a_malla(malla: MeshInstance3D, shader: Shader) -> void:
	if not malla.mesh:
		return
		
	# Recorre todas las superficies por si un bloque tiene más de una textura
	for i in range(malla.mesh.get_surface_count()):
		var mat_original = malla.mesh.surface_get_material(i)
		if not mat_original:
			mat_original = malla.get_active_material(i)
			
		if mat_original is BaseMaterial3D and mat_original.albedo_texture:
			var mat_mate = ShaderMaterial.new()
			mat_mate.shader = shader
			mat_mate.set_shader_parameter("tex", mat_original.albedo_texture)
			malla.set_surface_override_material(i, mat_mate)


# FUNCIÓN AÑADIDA PARA LA TRANSICIÓN
func _crear_fade_in(duracion: float) -> void:
	var capa_transicion = CanvasLayer.new()
	capa_transicion.layer = 10 
	add_child(capa_transicion)
	
	var fondo_negro = ColorRect.new()
	fondo_negro.color = Color(0, 0, 0, 1) # Empieza en negro total
	fondo_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_transicion.add_child(fondo_negro)
	
	var tween = create_tween()
	# Animamos el Alpha hacia 0.0 (totalmente transparente)
	tween.tween_property(fondo_negro, "color:a", 0.0, duracion)
	
	# Se autodestruye al terminar para no consumir memoria
	tween.tween_callback(capa_transicion.queue_free)
