extends "res://popup_kit/puzzle_popup.gd"
## Ventana con el esquema de la cámara de televisión del Apolo 12.
## El jugador arrastra la celda de batería desde el inventario del robot
## hasta el compartimiento de batería del esquema.

const DraggableItemScript := preload("res://popup_kit/draggable_item.gd")
const DropSlotScript := preload("res://popup_kit/drop_slot.gd")
const RUTA_FUENTE := "res://Fonts/UFO50Tall.ttf"
const ID_BATERIA := "bateria"

const AZUL := Color(0.45, 0.85, 1.0)
const TAM_ESQUEMA := Vector2(680, 400)
const RECT_SLOT := Rect2(330, 178, 120, 64)

## [texto, posición de la etiqueta, punto que señala]
const ETIQUETAS := [
	["LENS", Vector2(20, 40), Vector2(130, 120)],
	["HANDLE", Vector2(220, 18), Vector2(300, 62)],
	["VIDICON TUBE", Vector2(500, 22), Vector2(410, 125)],
	["BACK PANEL /\nCONNECTORS", Vector2(515, 120), Vector2(492, 160)],
	["BODY", Vector2(530, 262), Vector2(465, 235)],
	["BATTERY\nCOMPARTMENT", Vector2(60, 250), Vector2(330, 210)],
	["TRIPOD", Vector2(470, 345), Vector2(395, 340)],
]

var _fuente: Font
var _estado: Label
var _hint_slot: Label
var _slot: Panel


func _ready() -> void:
	close_delay_after_solve = 1.6
	if ResourceLoader.exists(RUTA_FUENTE):
		_fuente = load(RUTA_FUENTE)
	_construir()
	super._ready()


func _construir() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	vbox.add_child(_label("SCHEMATIC - TELEVISION CAMERA (APOLLO 12)", 28))

	# Esquema (plano azul con las partes)
	var esquema := Control.new()
	esquema.custom_minimum_size = TAM_ESQUEMA
	esquema.clip_contents = true
	vbox.add_child(esquema)
	esquema.draw.connect(_dibujar_esquema.bind(esquema))
	for e in ETIQUETAS:
		var l := _label(e[0], 16)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.position = e[1]
		l.modulate = AZUL
		esquema.add_child(l)

	_slot = DropSlotScript.new()
	_slot.accepted_item_id = ID_BATERIA
	_slot.only_accept_correct = true
	_slot.lock_when_correct = true
	_slot.position = RECT_SLOT.position
	_slot.size = RECT_SLOT.size
	_slot.add_theme_stylebox_override("panel", _estilo(Color(0.1, 0.1, 0.0, 0.6), Color(1, 0.85, 0.2)))
	esquema.add_child(_slot)
	_hint_slot = _label("DRAG\nHERE", 14)
	_hint_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hint_slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_slot.modulate = Color(1, 0.85, 0.2)
	_hint_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot.add_child(_hint_slot)
	_slot.item_placed.connect(func(_s, _i): _hint_slot.hide())

	# Inventario del robot
	var titulo_inv := _label("ROBOT INVENTORY", 22)
	titulo_inv.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(titulo_inv)
	var bandeja := HBoxContainer.new()
	bandeja.add_theme_constant_override("separation", 12)
	vbox.add_child(bandeja)
	var vistos := []
	for id in Inventario.items:
		if not vistos.has(id):
			vistos.append(id)
			_agregar_item(bandeja, id)
	if vistos.is_empty():
		bandeja.add_child(_label("(empty)", 18))

	_estado = _label("", 20)
	vbox.add_child(_estado)
	if Inventario.tiene(ID_BATERIA):
		_estado.text = "Drag the battery cell into the battery compartment"
	else:
		_estado.text = "You need a battery cell. Look under the scrap metal."
		_estado.modulate = Color(1, 0.6, 0.4)

	var cerrar := Button.new()
	cerrar.text = "Close [Esc]"
	cerrar.focus_mode = Control.FOCUS_NONE
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_END
	_aplicar_fuente(cerrar, 20)
	vbox.add_child(cerrar)
	close_button = cerrar


func _agregar_item(bandeja: Control, id: String) -> void:
	var col := VBoxContainer.new()
	bandeja.add_child(col)
	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(110, 88)
	caja.add_theme_stylebox_override("panel", _estilo(Color(0.05, 0.1, 0.15, 1), Color(0, 0.6, 0.8, 0.8)))
	col.add_child(caja)

	var textura: Texture2D
	var icono := Inventario.icono_de(id)
	if icono != "" and ResourceLoader.exists(icono):
		textura = load(icono)
	else:
		var vp := Inventario.crear_preview(id, Vector2i(160, 128))
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(vp)
		textura = vp.get_texture()

	var item: TextureRect = DraggableItemScript.new()
	item.item_id = id
	item.texture = textura
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.custom_minimum_size = Vector2(100, 78)
	item.size = Vector2(100, 78)
	item.tooltip_text = Inventario.nombre_de(id)
	caja.add_child(item)
	item.picked_up.connect(_on_item_tomado)

	var nombre := _label(Inventario.nombre_de(id), 14)
	col.add_child(nombre)


func _on_item_tomado(item) -> void:
	if item.item_id != ID_BATERIA and not is_solved:
		_estado.text = "%s does not go in the camera" % Inventario.nombre_de(item.item_id)


func _on_solved() -> void:
	_estado.text = "Battery installed! The camera is receiving power"
	_estado.modulate = Color(0.5, 1, 0.6)
	_slot.add_theme_stylebox_override("panel", _estilo(Color(0.1, 0.3, 0.1, 0.7), Color(0.4, 1, 0.5)))


func _dibujar_esquema(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, TAM_ESQUEMA), Color(0.03, 0.12, 0.25))
	var rejilla := Color(0.4, 0.7, 1.0, 0.12)
	for x in range(0, int(TAM_ESQUEMA.x), 20):
		c.draw_line(Vector2(x, 0), Vector2(x, TAM_ESQUEMA.y), rejilla)
	for y in range(0, int(TAM_ESQUEMA.y), 20):
		c.draw_line(Vector2(0, y), Vector2(TAM_ESQUEMA.x, y), rejilla)
	var w := 2.0
	# Cuerpo
	c.draw_rect(Rect2(220, 80, 250, 170), AZUL, false, w)
	# Lente (tubo + aros)
	c.draw_rect(Rect2(150, 110, 70, 100), AZUL, false, w)
	c.draw_arc(Vector2(150, 160), 50, PI * 0.5, PI * 1.5, 24, AZUL, w)
	c.draw_arc(Vector2(150, 160), 30, 0, TAU, 24, AZUL, w)
	c.draw_circle(Vector2(150, 160), 10, Color(AZUL, 0.5))
	# Asa
	c.draw_polyline(PackedVector2Array([Vector2(280, 80), Vector2(280, 55), Vector2(400, 55), Vector2(400, 80)]), AZUL, w)
	# Tubo vidicón (punteado)
	c.draw_dashed_line(Vector2(235, 110), Vector2(420, 110), AZUL, 1.5, 8)
	c.draw_dashed_line(Vector2(235, 145), Vector2(420, 145), AZUL, 1.5, 8)
	c.draw_dashed_line(Vector2(420, 110), Vector2(420, 145), AZUL, 1.5, 8)
	c.draw_dashed_line(Vector2(235, 110), Vector2(235, 145), AZUL, 1.5, 8)
	# Parte trasera + conectores
	c.draw_rect(Rect2(470, 95, 22, 140), AZUL, false, w)
	for i in 3:
		c.draw_rect(Rect2(492, 125 + i * 28, 10, 12), AZUL, false, 1.5)
	# Compartimiento de batería (marco)
	c.draw_rect(RECT_SLOT.grow(6), Color(1, 0.85, 0.2), false, 1.5)
	# Trípode
	var base := Vector2(345, 250)
	c.draw_line(base, base + Vector2(0, 30), AZUL, w)
	for d in [Vector2(-70, 110), Vector2(0, 115), Vector2(70, 110)]:
		c.draw_line(base + Vector2(0, 30), base + d, AZUL, w)
	# Líneas guía de las etiquetas
	for e in ETIQUETAS:
		var desde: Vector2 = e[1] + Vector2(0, 10)
		if e[1].x > e[2].x:
			desde = e[1] + Vector2(-4, 10)
		else:
			desde = e[1] + Vector2(_ancho_texto(e[0]) + 4, 10)
		c.draw_line(desde, e[2], Color(AZUL, 0.7), 1.0)
		c.draw_circle(e[2], 3, AZUL)


func _ancho_texto(t: String) -> float:
	var mayor := 0
	for linea in t.split("\n"):
		mayor = maxi(mayor, linea.length())
	return mayor * 8.0


func _estilo(bg: Color, borde: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = borde
	s.set_border_width_all(2)
	s.set_content_margin_all(10)
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
