extends CanvasLayer

signal textos_terminados
signal escritura_terminada # NUEVA SEÑAL: Avisa cuando termina de teclear

@onready var texto = $Panel/RichTextLabel

var lineas_dialogo: Array = []
var indice_actual: int = 0
var caracteres_mostrados: float = 0.0
var velocidad_escritura: float = 40.0 
var permite_input: bool = true # NUEVA VARIABLE: Para bloquear el teclado

func _ready() -> void:
	hide() 

# Agregamos "se_puede_pasar" con un valor por defecto en true
func mostrar_textos(nuevas_lineas: Array, se_puede_pasar: bool = true) -> void:
	lineas_dialogo = nuevas_lineas
	indice_actual = 0
	permite_input = se_puede_pasar # Guardamos si el jugador puede usar Enter
	show()
	_cargar_linea()

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
		if texto.visible_characters < texto.get_total_character_count():
			texto.visible_characters = texto.get_total_character_count()
			escritura_terminada.emit() # Avisamos también si el jugador lo aceleró
		else:
			indice_actual += 1
			if indice_actual < lineas_dialogo.size():
				_cargar_linea()
			else:
				hide()
				textos_terminados.emit()
