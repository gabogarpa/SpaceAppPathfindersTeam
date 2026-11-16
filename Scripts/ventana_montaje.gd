extends "res://popup_kit/puzzle_popup.gd"
## Esquema de un robot histórico. El jugador arrastra una pieza desde el inventario
## del robot hasta su lugar en el esquema. Basado en ventana_camara.gd (popup_kit).
## context.source = zona con robot_montaje.gd (titulo, imagen, slots, instaladas, instalar()).
## Cada slot: "pos" = punto de la imagen donde va la pieza; "caja" (opcional) = dónde se
## dibuja el recuadro si no cabe sobre el punto (puede salir de la imagen, p. ej. -0.1).

const DraggableItemScript := preload("res://popup_kit/draggable_item.gd")
const DropSlotScript := preload("res://popup_kit/drop_slot.gd")
const RUTA_FUENTE := "res://Fonts/UFO50Tall.ttf"

const AZUL := Color(0.45, 0.85, 1.0)
const AMARILLO := Color(1, 0.85, 0.2)
const VERDE := Color(0.4, 1, 0.5)
const TAM_ESQUEMA := Vector2(680, 380)
const TAM_SLOT := Vector2(104, 72)

var _fuente: Font
var _estado: Label
var _robot: Node
var _esquema: Control
var _rect_imagen := Rect2()
## [slot, punto en la imagen, etiqueta]
var _lineas: Array = []


func _ready() -> void:
	close_delay_after_solve = 1.4
	check_slots_automatically = false
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	super._ready()


func _on_opened() -> void:
	_robot = context.get("source")
	_construir()


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.6)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo(Color(0, 0, 0, 0.9), Color(0, 0.8, 1, 0.9)))
	centro.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	vbox.add_child(_label("SCHEMATIC - %s" % _robot.titulo, 26))

	_esquema = Control.new()
	_esquema.custom_minimum_size = TAM_ESQUEMA
	_esquema.clip_contents = true
	vbox.add_child(_esquema)
	_esquema.draw.connect(_dibujar_fondo)
	if _robot.imagen:
		var foto := TextureRect.new()
		foto.texture = _robot.imagen
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		foto.size = TAM_ESQUEMA
		foto.modulate = Color(1, 1, 1, 0.85)
		foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_esquema.add_child(foto)
		var tam: Vector2 = _robot.imagen.get_size()
		var escala := minf(TAM_ESQUEMA.x / tam.x, TAM_ESQUEMA.y / tam.y)
		_rect_imagen = Rect2((TAM_ESQUEMA - tam * escala) / 2.0, tam * escala)
	else:
		_rect_imagen = Rect2(Vector2.ZERO, TAM_ESQUEMA)
	var capa_lineas := Control.new()
	capa_lineas.size = TAM_ESQUEMA
	capa_lineas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_lineas.draw.connect(_dibujar_lineas.bind(capa_lineas))
	_esquema.add_child(capa_lineas)
	for datos in _robot.slots:
		_crear_slot(datos)

	var titulo_inv := _label("ROBOT INVENTORY - drag a component to its place", 20)
	titulo_inv.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(titulo_inv)
	var bandeja := HBoxContainer.new()
	bandeja.add_theme_constant_override("separation", 10)
	vbox.add_child(bandeja)
	var vistos := []
	for id in Inventario.items:
		if not vistos.has(id):
			vistos.append(id)
			_agregar_item(bandeja, id)
	if vistos.is_empty():
		bandeja.add_child(_label("(empty)", 18))

	_estado = _label("", 20)
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.custom_minimum_size.x = TAM_ESQUEMA.x
	vbox.add_child(_estado)
	if _robot.tiene_pieza_para_instalar():
		_estado.text = "Drag the component onto its highlighted place"
	else:
		_estado.text = "You don't have any missing component for %s" % _robot.titulo
		_estado.modulate = Color(1, 0.6, 0.4)

	var cerrar := Button.new()
	cerrar.text = "Close [Esc]"
	cerrar.focus_mode = Control.FOCUS_NONE
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_END
	_aplicar_fuente(cerrar, 20)
	vbox.add_child(cerrar)
	cerrar.pressed.connect(close)


func _crear_slot(datos: Dictionary) -> void:
	var id := String(datos.id)
	var punto: Vector2 = _rect_imagen.position + _rect_imagen.size * (datos.pos as Vector2)
	var centro_slot := punto
	if datos.has("caja"):
		centro_slot = _rect_imagen.position + _rect_imagen.size * (datos.caja as Vector2)
	var pos := (centro_slot - TAM_SLOT / 2.0).clamp(Vector2(4, 30), TAM_ESQUEMA - TAM_SLOT - Vector2(4, 4))
	var instalada: bool = _robot.instaladas.has(id)

	var slot: Panel = DropSlotScript.new()
	slot.accepted_item_id = id
	slot.only_accept_correct = true
	slot.lock_when_correct = true
	slot.position = pos
	slot.size = TAM_SLOT
	slot.add_theme_stylebox_override("panel", _estilo_slot(instalada))
	if instalada:
		slot.add_child(_crear_item(id))
	else:
		var pista := _label("DRAG\nHERE", 14)
		pista.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pista.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pista.modulate = AMARILLO
		pista.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(pista)
		slot.item_placed.connect(_on_pieza_colocada.bind(pista))
	_esquema.add_child(slot)

	var etiqueta := _label("%s\n%s" % [String(datos.get("etiqueta", "")), "INSTALLED" if instalada else Inventario.nombre_de(id)], 14)
	etiqueta.modulate = VERDE if instalada else AZUL
	etiqueta.add_theme_stylebox_override("normal", _estilo(Color(0, 0, 0, 0.75), Color(0, 0, 0, 0)))
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_esquema.add_child(etiqueta)
	etiqueta.reset_size()
	var arriba := pos.y - etiqueta.size.y - 4 >= 0
	etiqueta.position = Vector2(pos.x + (TAM_SLOT.x - etiqueta.size.x) / 2.0,
		pos.y - etiqueta.size.y - 4 if arriba else pos.y + TAM_SLOT.y + 4)
	etiqueta.position.x = clampf(etiqueta.position.x, 0, TAM_ESQUEMA.x - etiqueta.size.x)
	slot.set_meta("etiqueta", etiqueta)
	_lineas.append([slot, punto])


func _crear_item(id: String) -> TextureRect:
	var item: TextureRect = DraggableItemScript.new()
	item.item_id = id
	item.texture = _textura_de(id)
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.custom_minimum_size = Vector2(96, 66)
	item.size = Vector2(96, 66)
	item.tooltip_text = Inventario.nombre_de(id)
	return item


func _textura_de(id: String) -> Texture2D:
	var icono := Inventario.icono_de(id)
	if icono != "" and ResourceLoader.exists(icono):
		return load(icono)
	var vp := Inventario.crear_preview(id, Vector2i(160, 110))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	return vp.get_texture()


func _agregar_item(bandeja: Control, id: String) -> void:
	var col := VBoxContainer.new()
	bandeja.add_child(col)
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(104, 76)
	caja.add_theme_stylebox_override("panel", _estilo(Color(0.05, 0.1, 0.15, 1), Color(0, 0.6, 0.8, 0.8)))
	col.add_child(caja)
	var item := _crear_item(id)
	caja.add_child(item)
	item.picked_up.connect(_on_item_tomado)
	col.add_child(_label(Inventario.nombre_de(id), 14))


func _on_item_tomado(item) -> void:
	if is_solved:
		return
	if not _robot.pendientes().has(item.item_id):
		_estado.text = "%s does not belong to %s" % [Inventario.nombre_de(item.item_id), _robot.titulo]
		_estado.modulate = Color(1, 0.6, 0.4)
	else:
		_estado.text = "Drop the %s on: %s" % [Inventario.nombre_de(item.item_id), _etiqueta_de(item.item_id)]
		_estado.modulate = Color.WHITE


func _etiqueta_de(id: String) -> String:
	for datos in _robot.slots:
		if String(datos.id) == id:
			return String(datos.get("etiqueta", ""))
	return ""


func _on_pieza_colocada(slot, item, pista: Label) -> void:
	if not slot.is_correct():
		return
	pista.hide()
	slot.add_theme_stylebox_override("panel", _estilo_slot(true))
	var etiqueta: Label = slot.get_meta("etiqueta")
	etiqueta.text = "%s\nINSTALLED" % _etiqueta_de(item.item_id)
	etiqueta.modulate = VERDE
	_robot.instalar(item.item_id)
	_estado.text = "%s installed!" % Inventario.nombre_de(item.item_id)
	_estado.modulate = VERDE
	if not _robot.tiene_pieza_para_instalar():
		solve()


func _dibujar_fondo() -> void:
	_esquema.draw_rect(Rect2(Vector2.ZERO, TAM_ESQUEMA), Color(0.03, 0.12, 0.25))
	var rejilla := Color(0.4, 0.7, 1.0, 0.12)
	for x in range(0, int(TAM_ESQUEMA.x), 20):
		_esquema.draw_line(Vector2(x, 0), Vector2(x, TAM_ESQUEMA.y), rejilla)
	for y in range(0, int(TAM_ESQUEMA.y), 20):
		_esquema.draw_line(Vector2(0, y), Vector2(TAM_ESQUEMA.x, y), rejilla)


func _dibujar_lineas(c: Control) -> void:
	for l in _lineas:
		var slot: Control = l[0]
		var centro: Vector2 = slot.position + slot.size / 2.0
		var punto: Vector2 = l[1]
		if centro.distance_to(punto) > 8.0:
			c.draw_line(centro, punto, Color(AMARILLO, 0.8), 1.5)
		c.draw_circle(punto, 4, AMARILLO)


func _estilo_slot(instalada: bool) -> StyleBoxFlat:
	if instalada:
		return _estilo(Color(0.1, 0.3, 0.1, 0.75), VERDE)
	return _estilo(Color(0.1, 0.1, 0.0, 0.65), AMARILLO)


func _estilo(bg: Color, borde: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = borde
	s.set_border_width_all(2)
	s.set_content_margin_all(6)
	return s


func _label(texto: String, tam: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aplicar_fuente(l, tam)
	return l


func _aplicar_fuente(c: Control, tam: int) -> void:
	c.add_theme_font_size_override("font_size", tam)
	if _fuente:
		c.add_theme_font_override("font", _fuente)
