extends Node3D

@onready var caja_texto = $CajaTexto

func _ready() -> void:
	# 1. Creamos el fade in instantáneamente al cargar la escena
	_crear_fade_in(1.5)
	
	# 2. Mostramos los textos (el jugador podrá moverse mientras lee)
	caja_texto.mostrar_textos([
		"MISSION CONTROL: \nSPARK, welcome to Mars.",
		"MISSION CONTROL: \nSPARK, you have arrived at Ares Vallis. A new chapter in the robotic exploration of Mars began here.",
		"MISSION 03: \nTHE FIRST FOOTPRINTS",
		"Main objective: \nRecover and preserve three historic components from the Mars Pathfinder lander and the Sojourner rover."
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
