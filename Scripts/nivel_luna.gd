extends Node3D

@onready var caja_texto = $CajaTexto

func _ready() -> void:
	# 1. Creamos el fade in instantáneamente al cargar la escena
	_crear_fade_in(1.5)
	
	# 2. Mostramos los textos (el jugador podrá moverse mientras lee)
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
	
	var tween = create_tween()
	tween.tween_property(fondo_negro, "color:a", 0.0, duracion)
	tween.tween_callback(capa_transicion.queue_free)
