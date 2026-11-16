extends Node
## Autoload "Inventario": guarda los objetos del jugador, la herramienta equipada
## y dibuja el HUD (avisos + ventana de inventario).
## Registrar en Project Settings > Globals > Autoload con el nombre "Inventario".

signal item_agregado(id: String)
signal herramienta_equipada(id: String)
signal inventario_toggled(abierto: bool)

const ACCION_INVENTARIO := "inventario"
const ACCION_USAR := "usar_herramienta"
const TECLA_INVENTARIO := KEY_I
const TECLA_USAR := KEY_E
const RUTA_FUENTE := "res://Fonts/UFO50Tall.ttf"

## Catálogo de objetos. Agrega aquí nuevas piezas o herramientas.
var ITEMS := {
	"escoba": {
		"nombre": "Escoba",
		"modelo": "res://Models/Objetos/Escoba_Voxel.glb",
		"herramienta": true,
	},
	"brazo_robotico": {
		"nombre": "Brazo robotico",
		"modelo": "res://Models/Objetos/Brazo_Excavador_Voxel.glb",
		"herramienta": false,
	},
}

var items: Array[String] = []
var equipada := ""
var abierto := false

var _capa: CanvasLayer
var _aviso_panel: PanelContainer
var _aviso_label: Label
var _equipada_label: Label
var _ventana: Control
var _grid: GridContainer
var _info_label: Label
var _fuente: Font
var _previews: Array[Node3D] = []
var _prev_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _prev_paused := false
var _aviso_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_registrar_accion(ACCION_INVENTARIO, TECLA_INVENTARIO)
	_registrar_accion(ACCION_USAR, TECLA_USAR)
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	_construir_hud()


# ---------------------------------------------------------------- API pública

func agregar(id: String) -> void:
	if not ITEMS.has(id):
		push_warning("Inventario: item desconocido '%s'" % id)
	items.append(id)
	item_agregado.emit(id)
	if abierto:
		_refrescar_ventana()


func tiene(id: String) -> bool:
	return items.has(id)


func quitar(id: String) -> void:
	items.erase(id)
	if equipada == id and not items.has(id):
		equipar("")
	if abierto:
		_refrescar_ventana()


func equipar(id: String) -> void:
	equipada = id
	if id == "":
		_equipada_label.text = ""
	else:
		_equipada_label.text = "Equipado: %s\n[%s] Usar" % [nombre_de(id), tecla_de(ACCION_USAR)]
	herramienta_equipada.emit(id)


func nombre_de(id: String) -> String:
	return ITEMS.get(id, {}).get("nombre", id)


func modelo_de(id: String) -> String:
	return ITEMS.get(id, {}).get("modelo", "")


func es_herramienta(id: String) -> bool:
	return ITEMS.get(id, {}).get("herramienta", false)


## Texto de la tecla asignada a una acción (p. ej. "E").
func tecla_de(accion: String) -> String:
	if InputMap.has_action(accion):
		for ev in InputMap.action_get_events(accion):
			if ev is InputEventKey:
				var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
				return OS.get_keycode_string(code)
	return accion


## Muestra un aviso arriba de la pantalla. duracion <= 0 = se queda hasta ocultar_aviso().
func mostrar_aviso(texto: String, duracion: float = 0.0) -> void:
	_aviso_id += 1
	var id := _aviso_id
	_aviso_label.text = texto
	_aviso_panel.show()
	if duracion > 0.0:
		await get_tree().create_timer(duracion, true, false, true).timeout
		if id == _aviso_id:
			_aviso_panel.hide()


func ocultar_aviso() -> void:
	_aviso_id += 1
	_aviso_panel.hide()


func abrir() -> void:
	if abierto:
		return
	var popups := get_node_or_null("/root/PopupManager")
	if popups and popups.has_method("is_open") and popups.is_open():
		return
	abierto = true
	_prev_mouse_mode = Input.mouse_mode
	_prev_paused = get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_refrescar_ventana()
	_ventana.show()
	inventario_toggled.emit(true)


func cerrar() -> void:
	if not abierto:
		return
	abierto = false
	_ventana.hide()
	get_tree().paused = _prev_paused
	Input.mouse_mode = _prev_mouse_mode
	inventario_toggled.emit(false)


func alternar() -> void:
	if abierto:
		cerrar()
	else:
		abrir()


# ---------------------------------------------------------------- Input

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACCION_INVENTARIO):
		alternar()
		get_viewport().set_input_as_handled()
	elif abierto and event.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if abierto:
		for p in _previews:
			if is_instance_valid(p):
				p.rotate_y(delta * 1.2)


func _registrar_accion(accion: String, tecla: Key) -> void:
	if InputMap.has_action(accion) and not InputMap.action_get_events(accion).is_empty():
		return
	if not InputMap.has_action(accion):
		InputMap.add_action(accion)
	var ev := InputEventKey.new()
	ev.physical_keycode = tecla
	InputMap.action_add_event(accion, ev)


# ---------------------------------------------------------------- UI

func _estilo_panel(alpha: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, alpha)
	s.border_color = Color(0.0, 0.8, 1.0, 0.9)
	s.set_border_width_all(2)
	s.set_content_margin_all(12)
	return s


func _label(texto: String, tam: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	if _fuente:
		l.add_theme_font_override("font", _fuente)
	return l


func _construir_hud() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 50
	add_child(_capa)

	# Aviso (arriba al centro)
	var arriba := MarginContainer.new()
	arriba.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	arriba.grow_horizontal = Control.GROW_DIRECTION_BOTH
	arriba.add_theme_constant_override("margin_top", 24)
	arriba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(arriba)
	_aviso_panel = PanelContainer.new()
	_aviso_panel.add_theme_stylebox_override("panel", _estilo_panel(0.7))
	_aviso_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso_panel.hide()
	arriba.add_child(_aviso_panel)
	_aviso_label = _label("", 28)
	_aviso_panel.add_child(_aviso_label)

	# Herramienta equipada (arriba a la derecha)
	_equipada_label = _label("", 22)
	_equipada_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_equipada_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_equipada_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_equipada_label.position += Vector2(-16, 110)
	_equipada_label.modulate = Color(0.6, 0.95, 1.0)
	_capa.add_child(_equipada_label)

	# Ventana de inventario
	_ventana = Control.new()
	_ventana.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ventana.hide()
	_capa.add_child(_ventana)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ventana.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ventana.add_child(centro)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel(0.85))
	centro.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	vbox.add_child(_label("INVENTARIO", 40))
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(_grid)
	_info_label = _label("", 22)
	vbox.add_child(_info_label)


func _refrescar_ventana() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_previews.clear()
	var vistos := {}
	for id in items:
		vistos[id] = vistos.get(id, 0) + 1
	for id in vistos:
		_grid.add_child(_crear_slot(id, vistos[id]))
	for i in range(maxi(0, 4 - vistos.size())):
		_grid.add_child(_crear_slot("", 0))
	_info_label.text = "Clic en una herramienta para equiparla\n[%s] Cerrar" % tecla_de(ACCION_INVENTARIO)


func _crear_slot(id: String, cantidad: int) -> Control:
	var boton := Button.new()
	boton.custom_minimum_size = Vector2(150, 170)
	boton.toggle_mode = true
	boton.focus_mode = Control.FOCUS_NONE
	if id == "":
		boton.disabled = true
		return boton
	boton.button_pressed = id == equipada
	boton.tooltip_text = nombre_de(id)
	boton.pressed.connect(_on_slot_pressed.bind(id))

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(vbox)

	var contenedor := SubViewportContainer.new()
	contenedor.stretch = true
	contenedor.custom_minimum_size = Vector2(150, 120)
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(contenedor)
	contenedor.add_child(_crear_preview(id))

	var texto := nombre_de(id)
	if cantidad > 1:
		texto += " x%d" % cantidad
	if id == equipada:
		texto += "\n(equipado)"
	var l := _label(texto, 20)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(l)
	return boton


func _crear_preview(id: String) -> SubViewport:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(150, 120)
	var pivote := Node3D.new()
	vp.add_child(pivote)
	var ruta := modelo_de(id)
	var radio := 1.0
	if ruta != "" and ResourceLoader.exists(ruta):
		var modelo: Node3D = load(ruta).instantiate()
		pivote.add_child(modelo)
		var caja := calcular_aabb(modelo)
		modelo.position = -caja.get_center()
		radio = maxf(caja.size.length() * 0.5, 0.1)
	_previews.append(pivote)
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.position = Vector3(0, radio * 0.6, radio * 2.8)
	vp.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, 30, 0)
	vp.add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	vp.add_child(env)
	return vp


func _on_slot_pressed(id: String) -> void:
	if not es_herramienta(id):
		mostrar_aviso("%s no es una herramienta" % nombre_de(id), 2.0)
	elif equipada == id:
		equipar("")
	else:
		equipar(id)
		mostrar_aviso("%s equipada" % nombre_de(id), 1.5)
	_refrescar_ventana()


## AABB de todas las mallas de un nodo, en el espacio local de ese nodo.
static func calcular_aabb(raiz: Node) -> AABB:
	var resultado := [null]
	_acumular_aabb(raiz, Transform3D.IDENTITY, resultado)
	return resultado[0] if resultado[0] != null else AABB(Vector3.ZERO, Vector3.ONE)


static func _acumular_aabb(nodo: Node, xf: Transform3D, resultado: Array) -> void:
	for hijo in nodo.get_children():
		var xf_hijo := xf
		if hijo is Node3D:
			xf_hijo = xf * hijo.transform
		if hijo is MeshInstance3D and hijo.mesh:
			var caja: AABB = xf_hijo * hijo.mesh.get_aabb()
			resultado[0] = caja if resultado[0] == null else resultado[0].merge(caja)
		_acumular_aabb(hijo, xf_hijo, resultado)
