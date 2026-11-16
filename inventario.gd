extends Node
# Autoload "Inventario": objetos del robot, herramienta equipada, avisos en pantalla
# y creación de la ventana flotante del almacén.

signal objeto_agregado(id: String)
signal equipado_cambiado(id: String)

const DB := preload("res://objetos_db.gd")
const VentanaAlmacen := preload("res://almacen_ventana.gd")

var objetos: Array[String] = []
var equipado: String = ""

var _pista: Label
var _aviso: Label
var _prompt: Label
var _tween: Tween

func _ready() -> void:
	_registrar_tecla("interactuar", KEY_E)     # recoger objetos
	_registrar_tecla("abrir_almacen", KEY_I)   # abrir/cerrar almacén
	_registrar_tecla("usar_objeto", KEY_F)     # usar herramienta equipada
	_crear_avisos()

	var ventana = VentanaAlmacen.new()
	ventana.inventario = self
	add_child(ventana)

func _registrar_tecla(accion: String, tecla: Key) -> void:
	if InputMap.has_action(accion):
		return
	InputMap.add_action(accion)
	var ev := InputEventKey.new()
	ev.physical_keycode = tecla
	InputMap.action_add_event(accion, ev)

# ------------------------------------------------------------------ interfaz

func _crear_avisos() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 100  # por encima del filtro retro
	add_child(capa)

	_pista = Label.new()
	_pista.position = Vector2(16, 16)
	_estilizar(_pista)
	capa.add_child(_pista)

	_aviso = Label.new()
	_aviso.position = Vector2(16, 52)
	_aviso.modulate.a = 0.0
	_estilizar(_aviso)
	capa.add_child(_aviso)

	# Mensaje fijo centrado abajo ("Usa la escoba [F]")
	_prompt = Label.new()
	_prompt.anchor_left = 0.0
	_prompt.anchor_right = 1.0
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -110.0
	_prompt.offset_bottom = -70.0
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_estilizar(_prompt)
	_prompt.add_theme_font_size_override("font_size", 26)
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	capa.add_child(_prompt)

	_actualizar_pista()

func _estilizar(l: Label) -> void:
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)

func _actualizar_pista() -> void:
	var t := "[I] Almacén (%d)" % objetos.size()
	if equipado != "":
		t += "    Equipado: %s  [F] usar" % DB.obtener(equipado)["nombre"]
	_pista.text = t

func mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	_aviso.modulate.a = 1.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(2.0)
	_tween.tween_property(_aviso, "modulate:a", 0.0, 0.8)

func mostrar_prompt(texto: String) -> void:
	_prompt.text = texto
	_prompt.visible = true

func ocultar_prompt() -> void:
	_prompt.visible = false

# ------------------------------------------------------------------ datos

func agregar(id: String) -> void:
	if id in objetos:
		return
	objetos.append(id)
	_actualizar_pista()
	mostrar_aviso("¡Obtuviste: %s!" % DB.obtener(id)["nombre"])
	objeto_agregado.emit(id)
	print("Almacén: ", objetos)

func tiene(id: String) -> bool:
	return id in objetos

func equipar(id: String) -> void:
	if not tiene(id):
		return
	equipado = id
	_actualizar_pista()
	mostrar_aviso("Equipaste: %s" % DB.obtener(id)["nombre"])
	equipado_cambiado.emit(id)

func desequipar() -> void:
	equipado = ""
	_actualizar_pista()
	mostrar_aviso("Guardaste la herramienta")
	equipado_cambiado.emit("")
