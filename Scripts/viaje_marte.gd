extends Node3D
## Transición Luna -> Marte. Usa la escena Viajando, precarga el nivel de Marte en
## segundo plano (igual que el tutorial con la Luna) y cambia de escena tras el viaje.

const RUTA_NIVEL_MARTE = "res://Escenas/nivel_marte.tscn"
## Segundos que dura el viaje antes del fade out.
const DURACION_VIAJE := 6.0
const DURACION_FADE := 1.5

@onready var caja_texto = $CajaTexto


func _ready() -> void:
	# Cargamos Marte en segundo plano desde el primer frame
	ResourceLoader.load_threaded_request(RUTA_NIVEL_MARTE)
	Inventario.reiniciar()
	Inventario.bloqueado = true

	_crear_fade_in(DURACION_FADE)
	caja_texto.mostrar_textos([
		"Leaving lunar orbit...\nCourse set for Mars."
	], false)

	await get_tree().create_timer(DURACION_VIAJE).timeout
	await _crear_fade_out(DURACION_FADE)

	var nivel_cargado = ResourceLoader.load_threaded_get(RUTA_NIVEL_MARTE)
	Inventario.bloqueado = false
	get_tree().change_scene_to_packed(nivel_cargado)


func _crear_fade_in(duracion: float) -> void:
	var capa_transicion = CanvasLayer.new()
	capa_transicion.layer = 10
	add_child(capa_transicion)

	var fondo_negro = ColorRect.new()
	fondo_negro.color = Color(0, 0, 0, 1)
	fondo_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_transicion.add_child(fondo_negro)

	var tween = create_tween()
	tween.tween_property(fondo_negro, "color:a", 0.0, duracion)
	tween.tween_callback(capa_transicion.queue_free)


func _crear_fade_out(duracion: float) -> void:
	var capa_transicion = CanvasLayer.new()
	capa_transicion.layer = 10
	add_child(capa_transicion)

	var fondo_negro = ColorRect.new()
	fondo_negro.color = Color(0, 0, 0, 0)
	fondo_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_transicion.add_child(fondo_negro)

	var tween = create_tween()
	tween.tween_property(fondo_negro, "color:a", 1.0, duracion)
	await tween.finished
