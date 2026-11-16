extends Node3D

const RUTA_VIAJE_MARTE = "res://Escenas/viaje_marte.tscn"

@onready var caja_texto = $CajaTexto

func _ready() -> void:
	# 1. Creamos el fade in instantáneamente al cargar la escena
	_crear_fade_in(1.5)
	
	var inventario := get_node_or_null("/root/Inventario")
	if inventario:
		inventario.reiniciar()
		inventario.iniciar_mision(inventario.OBJETIVOS, true)
		inventario.mision_completada.connect(_on_luna_completada, CONNECT_ONE_SHOT)

	# 2. Mostramos los textos; el juego queda en pausa hasta terminar la introduccion
	var robot := get_node_or_null("MoonBot/CharacterBody3D")
	caja_texto.textos_terminados.connect(_on_intro_terminada.bind(robot, inventario), CONNECT_ONE_SHOT)
	caja_texto.mostrar_textos([
		"MISSION CONTROL: \nLanding confirmed. SPARK, welcome to Oceanus Procellarum.",
		"MISSION CONTROL: \nYou have arrived at the place where the stories of Surveyor 3 and Apollo 12 intersect. Our work begins now.",
		"MISSION 01: \n180 METERS FROM THE PAST",
		"Main objective: \nRecover and preserve three historic components from Surveyor 3 and Apollo 12."
	])


func _crear_fade_in(duracion: float) -> void:
	var capa_transicion = CanvasLayer.new()
	capa_transicion.layer = 10 
	add_child(capa_transicion)
	
	var fondo_negro = ColorRect.new()
	fondo_negro.color = Color(0, 0, 0, 1) # Empieza en negro total
	fondo_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_transicion.add_child(fondo_negro)
	
	# El fade sigue aunque el juego esté en pausa por el texto
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fondo_negro, "color:a", 0.0, duracion)
	tween.tween_callback(capa_transicion.queue_free)


func _crear_fade_out(duracion: float) -> void:
	var capa_transicion = CanvasLayer.new()
	capa_transicion.layer = 10
	add_child(capa_transicion)

	var fondo_negro = ColorRect.new()
	fondo_negro.color = Color(0, 0, 0, 0) # Empieza en transparente
	fondo_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_transicion.add_child(fondo_negro)

	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fondo_negro, "color:a", 1.0, duracion) # Va hacia negro total
	await tween.finished


func _on_intro_terminada(robot: Node, inventario: Node) -> void:
	if robot and "puede_moverse" in robot:
		robot.puede_moverse = true
	if inventario:
		inventario.mostrar_aviso("Arrow keys: Move   [E] Use tool   [I] Inventory", 5.0)


## Al terminar todas las misiones de la Luna (y cerrar el archivo histórico) viajamos a Marte.
func _on_luna_completada() -> void:
	ResourceLoader.load_threaded_request(RUTA_VIAJE_MARTE)
	var inventario := get_node("/root/Inventario")
	await inventario.esperar_ventanas_info()
	inventario.bloqueado = true
	var robot := get_node_or_null("MoonBot/CharacterBody3D")
	if robot and "puede_moverse" in robot:
		robot.puede_moverse = false
	await get_tree().create_timer(1.0).timeout
	await _crear_fade_out(1.5)
	var viaje = ResourceLoader.load_threaded_get(RUTA_VIAJE_MARTE)
	get_tree().change_scene_to_packed(viaje)
