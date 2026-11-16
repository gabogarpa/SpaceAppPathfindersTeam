extends Node3D
## Transicion Luna -> Marte: muestra la escena "viajando" durante 6 segundos
## mientras precarga el nivel de Marte (igual que el tutorial con la Luna).

const RUTA_NIVEL_MARTE = "res://Escenas/nivel_marte.tscn"
const DURACION := 6.0
const FADE := 1.5

@onready var caja_texto = $CajaTexto


func _ready() -> void:
	ResourceLoader.load_threaded_request(RUTA_NIVEL_MARTE)
	var inventario := get_node_or_null("/root/Inventario")
	if inventario:
		inventario.bloqueado = true
	var robot := get_node_or_null("Viajando/MoonBot/CharacterBody3D")
	if robot and "puede_moverse" in robot:
		robot.puede_moverse = false
	await _crear_fade_in(FADE)
	caja_texto.mostrar_textos(["MISSION CONTROL: \nCourse set for Mars. Hold on, SPARK..."], false)
	await get_tree().create_timer(DURACION - FADE * 2.0).timeout
	await _crear_fade_out(FADE)
	var nivel_cargado = ResourceLoader.load_threaded_get(RUTA_NIVEL_MARTE)
	get_tree().change_scene_to_packed(nivel_cargado)


func _crear_fade_in(duracion: float) -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 1)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fondo, "color:a", 0.0, duracion)
	tween.tween_callback(capa.queue_free)
	await tween.finished


func _crear_fade_out(duracion: float) -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fondo, "color:a", 1.0, duracion)
	await tween.finished
