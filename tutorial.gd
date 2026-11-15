extends Node3D

@onready var caja_texto = $CajaTexto
@onready var luz_foco = $Viajando/SpotLight3D 
@onready var imagen_1 = $AD 
@onready var imagen_2 = $WS

var esperando_calibracion: bool = false
var movio_arriba: bool = false
var movio_abajo: bool = false
var movio_izda: bool = false
var movio_dcha: bool = false

signal calibracion_completada 

# Guardamos la ruta exacta del nivel que queremos precargar
const RUTA_NIVEL_LUNA = "res://Escenas/NivelLuna.tscn"

func _ready() -> void:
	# 1. ORDENAMOS A GODOT CARGAR EL NIVEL EN SEGUNDO PLANO DESDE EL PRIMER FRAME
	ResourceLoader.load_threaded_request(RUTA_NIVEL_LUNA)
	
	var energia_original = luz_foco.light_energy
	luz_foco.light_energy = 0.0
	luz_foco.visible = true 
	
	imagen_1.modulate.a = 0.0
	imagen_2.modulate.a = 0.0
	
	await _crear_fade_in(2.5) 
	
	caja_texto.mostrar_textos([
		"Navigation systems stabilized...",
		"Approaching lunar surface...",
		"Preparing SPARK motion test environment...",
		"Initializing SPARK systems..."
	])
	await caja_texto.textos_terminados
	
# 3. CREAMOS EL TWEEN EN PARALELO
	var tween_efectos = create_tween()
	tween_efectos.set_parallel(true) # Todo lo que sigue ocurrirá a la vez
	
	# Animamos la luz de 0 a su energía original
	tween_efectos.tween_property(luz_foco, "light_energy", energia_original, 0.5)
	
	# Animamos la transparencia (modulate:a) de las imágenes de 0.0 a 1.0 (100% visible)
	tween_efectos.tween_property(imagen_1, "modulate:a", 1.0, 0.5)
	tween_efectos.tween_property(imagen_2, "modulate:a", 1.0, 0.5)
	
	# Esperamos a que terminen estas tres animaciones simultáneas (0.5 seg)
	await tween_efectos.finished
	
	esperando_calibracion = true
	await calibracion_completada
	
	# 7. Lanzamos el último texto y le pasamos "false" para que NO se pueda quitar con Enter
	caja_texto.mostrar_textos([
		"SPARK systems calibrated successfully."
	], false)
	
	# 8. Esperamos SOLAMENTE a que la máquina termine de escribir (la nueva señal)
	await caja_texto.escritura_terminada
	
	# 9. Desde el frame exacto en que aparece el punto final, empiezan a contar los 4 segundos
	await get_tree().create_timer(4.0).timeout
	
	# 10. ¡Viaje a la luna!
	var nivel_cargado = ResourceLoader.load_threaded_get(RUTA_NIVEL_LUNA)
	get_tree().change_scene_to_packed(nivel_cargado)

func _process(_delta: float) -> void:
	if esperando_calibracion:
		if Input.is_action_pressed("ui_up"): movio_arriba = true
		if Input.is_action_pressed("ui_down"): movio_abajo = true
		if Input.is_action_pressed("ui_left"): movio_izda = true
		if Input.is_action_pressed("ui_right"): movio_dcha = true
		
		if movio_arriba and movio_abajo and movio_izda and movio_dcha:
			esperando_calibracion = false 
			calibracion_completada.emit() 


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
	await tween.finished
