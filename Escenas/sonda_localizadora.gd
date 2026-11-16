extends Node3D

@export var radio_deteccion: float = 120.0 
@export var distancia_maxima_frecuencia: float = 10.0 # Ajustado a 10 metros
@onready var onda_visual = $OndaVisual

var tween_actual: Tween
var temporizador_pulso: float = 0.0

func _ready() -> void:
	onda_visual.hide()
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0, 0.8, 1, 1) 
	material.emission_enabled = true
	material.emission = Color(0, 0.8, 1, 1) 
	material.emission_energy_multiplier = 2.0
	onda_visual.material_override = material

func _process(delta: float) -> void:
	# El radar solo se activa cuando hay un paso de la mision que seguir
	# (al conseguir una herramienta) y apunta al lugar donde hay que interactuar.
	var objetivo_mas_cercano := _objetivo_guiado()
	var distancia_minima: float = 0.0
	if objetivo_mas_cercano:
		distancia_minima = global_position.distance_to(objetivo_mas_cercano.global_position)

	if objetivo_mas_cercano:
		if no_estan_en_misma_posicion(global_position, objetivo_mas_cercano.global_position):
			look_at(objetivo_mas_cercano.global_position, Vector3.UP)
			
		var factor_cercania = 0.0
		if distancia_minima <= distancia_maxima_frecuencia:
			factor_cercania = 1.0
		else:
			factor_cercania = clampf(1.0 - ((distancia_minima - distancia_maxima_frecuencia) / (radio_deteccion - distancia_maxima_frecuencia)), 0.0, 1.0)
		
		# Intermitencia reducida: el pulso más rápido ahora tarda 0.3s en lugar de 0.2s
		var tiempo_entre_ondas = lerp(2.0, 0.3, factor_cercania)
		
		temporizador_pulso -= delta
		if temporizador_pulso <= 0.0:
			_lanzar_pulso(factor_cercania)
			temporizador_pulso = tiempo_entre_ondas
			
	else:
		onda_visual.hide()
		if tween_actual and tween_actual.is_valid():
			tween_actual.kill()
		temporizador_pulso = 0.0


## Paso actual de la mision segun el inventario:
## escoba -> polvo, brazo -> bateria -> camara, luego generador -> estacion.
func _paso_actual() -> String:
	var inv = get_node_or_null("/root/Inventario")
	if inv == null or inv.bloqueado:
		return ""
	var hay_herramienta := false
	for id in inv.items:
		if inv.es_herramienta(id):
			hay_herramienta = true
	if not hay_herramienta:
		return ""
	var hechos: Array = inv.objetivos_completados
	if not hechos.has("brazo_robotico"):
		return "polvo"
	if not hechos.has("camara"):
		return "camara" if inv.tiene("bateria") else "bateria"
	if not hechos.has("estacion"):
		return "estacion" if inv.tiene("snap27") else "snap"
	return ""


func _objetivo_guiado() -> Node3D:
	# Niveles con su propia guia (p. ej. Marte) devuelven los objetivos posibles.
	var escena := get_tree().current_scene
	if escena and escena.has_method("objetivos_guia"):
		return _mas_cercano(escena.objetivos_guia())
	var paso := _paso_actual()
	if paso == "":
		return null
	for n in get_tree().get_nodes_in_group("guia_" + paso):
		if is_instance_valid(n) and n is Node3D:
			return n
	return null

func _mas_cercano(nodos: Array) -> Node3D:
	var mejor: Node3D = null
	var distancia := INF
	for n in nodos:
		if is_instance_valid(n) and n is Node3D and n.is_inside_tree():
			var d := global_position.distance_squared_to(n.global_position)
			if d < distancia:
				distancia = d
				mejor = n
	return mejor

func _lanzar_pulso(factor_cercania: float) -> void:
	onda_visual.show()
	
	if tween_actual and tween_actual.is_valid():
		tween_actual.kill()
		
	onda_visual.scale = Vector3(0.1, 0.1, 0.1)
	onda_visual.position.z = 0.0
	onda_visual.material_override.albedo_color.a = 1.0
	
	# Animación suavizada: el viaje del anillo ahora tarda 0.25s en su punto más frenético
	var duracion_anim = lerp(1.2, 0.25, factor_cercania)
	
	tween_actual = create_tween()
	tween_actual.set_parallel(true)
	tween_actual.tween_property(onda_visual, "scale", Vector3(4.0, 4.0, 4.0), duracion_anim)
	tween_actual.tween_property(onda_visual, "position:z", -3.0, duracion_anim)
	tween_actual.tween_property(onda_visual.material_override, "albedo_color:a", 0.0, duracion_anim)

func no_estan_en_misma_posicion(pos1: Vector3, pos2: Vector3) -> bool:
	return pos1.distance_squared_to(pos2) > 0.001

