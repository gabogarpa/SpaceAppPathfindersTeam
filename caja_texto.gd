extends CanvasLayer

signal textos_terminados
signal escritura_terminada # NUEVA SEÑAL: Avisa cuando termina de teclear

@onready var texto = $Panel/RichTextLabel

var lineas_dialogo: Array = []
var indice_actual: int = 0
var caracteres_mostrados: float = 0.0
var velocidad_escritura: float = 40.0 
var permite_input: bool = true # NUEVA VARIABLE: Para bloquear el teclado

# Mientras hay un texto que se pasa con Enter, el juego queda en pausa.
var _pausado_por_texto: bool = false
var _pausa_previa: bool = false
var _bloqueo_previo: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide() 

# Agregamos "se_puede_pasar" con un valor por defecto en true
func mostrar_textos(nuevas_lineas: Array, se_puede_pasar: bool = true) -> void:
	lineas_dialogo = nuevas_lineas
	indice_actual = 0
	permite_input = se_puede_pasar # Guardamos si el jugador puede usar Enter
	var pista = get_node_or_null("Panel/Continuar")
	if pista:
		pista.visible = se_puede_pasar
	show()
	_pausar(se_puede_pasar)
	_cargar_linea()


func _pausar(activar: bool) -> void:
	var inventario := get_node_or_null("/root/Inventario")
	if activar and not _pausado_por_texto:
		_pausado_por_texto = true
		_pausa_previa = get_tree().paused
		get_tree().paused = true
		if inventario:
			_bloqueo_previo = inventario.bloqueado
			inventario.bloqueado = true
	elif not activar and _pausado_por_texto:
		_pausado_por_texto = false
		get_tree().paused = _pausa_previa
		if inventario:
			inventario.bloqueado = _bloqueo_previo

func _cargar_linea() -> void:
	texto.text = lineas_dialogo[indice_actual]
	texto.visible_characters = 0
	caracteres_mostrados = 0.0

func _process(delta: float) -> void:
	if visible and texto.visible_characters < texto.get_total_character_count():
		var caracteres_previos = texto.visible_characters
		
		caracteres_mostrados += velocidad_escritura * delta
		texto.visible_characters = int(caracteres_mostrados)
		
		# Si en este preciso fotograma se terminó de escribir la frase por completo
		if caracteres_previos < texto.get_total_character_count() and texto.visible_characters >= texto.get_total_character_count():
			escritura_terminada.emit() # Avisamos al Director

func _input(event: InputEvent) -> void:
	if not permite_input: return # Si está bloqueado, el jugador no puede hacer nada aquí
	
	if visible and event.is_action_pressed("ui_accept"): 
		get_viewport().set_input_as_handled()
		if texto.visible_characters < texto.get_total_character_count():
			texto.visible_characters = texto.get_total_character_count()
			escritura_terminada.emit() # Avisamos también si el jugador lo aceleró
		else:
			indice_actual += 1
			if indice_actual < lineas_dialogo.size():
				_cargar_linea()
			else:
				hide()
				_pausar(false)
				textos_terminados.emit()
