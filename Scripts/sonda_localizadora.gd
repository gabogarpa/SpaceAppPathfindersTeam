extends Node3D

@export var radio_deteccion: float = 100.0 
@export var distancia_maxima_frecuencia: float = 10.0
@onready var onda_visual = $OndaVisual

# Referencia al cuerpo del personaje (padre de la sonda) para saber hacia dónde mira
@onready var personaje: Node3D = get_parent()

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
	var objetos = get_tree().get_nodes_in_group("objeto_clave")
	var objetivo_mas_cercano: Node3D = null
	var distancia_minima: float = radio_deteccion
	
	# Vector frontal del personaje en el plano horizontal (por defecto -Z en Godot)
	# Si tu modelo de MoonBot mira hacia +Z, quítale el signo menos a global_transform.basis.z
	var frente_personaje = personaje.global_transform.basis.z
	frente_personaje.y = 0.0
	frente_personaje = frente_personaje.normalized()
	
	for obj in objetos:
		if is_instance_valid(obj) and obj is Node3D:
			var distancia = global_position.distance_to(obj.global_position)
			
			if distancia <= distancia_minima:
				# Vector desde el personaje hacia el objeto (ignorando diferencia de altura)
				var dir_al_objeto = obj.global_position - personaje.global_position
				dir_al_objeto.y = 0.0
				dir_al_objeto = dir_al_objeto.normalized()
				
				# El producto punto (dot) devuelve >= 0.0 si el ángulo está dentro de los 180° frontales
				# (90° a la izquierda y 90° a la derecha). Si está detrás, devuelve un número negativo.
				if frente_personaje.dot(dir_al_objeto) >= 0.0:
					distancia_minima = distancia
					objetivo_mas_cercano = obj
				
	if objetivo_mas_cercano:
		if no_estan_en_misma_posicion(global_position, objetivo_mas_cercano.global_position):
			look_at(objetivo_mas_cercano.global_position, Vector3.UP)
			
		var factor_cercania = 0.0
		if distancia_minima <= distancia_maxima_frecuencia:
			factor_cercania = 1.0
		else:
			factor_cercania = 1.0 - ((distancia_minima - distancia_maxima_frecuencia) / (radio_deteccion - distancia_maxima_frecuencia))
		
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

func _lanzar_pulso(factor_cercania: float) -> void:
	onda_visual.show()
	
	if tween_actual and tween_actual.is_valid():
		tween_actual.kill()
		
	onda_visual.scale = Vector3(0.1, 0.1, 0.1)
	onda_visual.position.z = 0.0
	onda_visual.material_override.albedo_color.a = 1.0
	
	var duracion_anim = lerp(1.2, 0.25, factor_cercania)
	
	tween_actual = create_tween()
	tween_actual.set_parallel(true)
	tween_actual.tween_property(onda_visual, "scale", Vector3(4.0, 4.0, 4.0), duracion_anim)
	tween_actual.tween_property(onda_visual, "position:z", -3.0, duracion_anim)
	tween_actual.tween_property(onda_visual, "material_override:albedo_color:a", 0.0, duracion_anim)

func no_estan_en_misma_posicion(pos1: Vector3, pos2: Vector3) -> bool:
	return pos1.distance_squared_to(pos2) > 0.001
