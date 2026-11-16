extends CanvasLayer
# Ventana flotante del almacén. Se abre/cierra con la tecla I y se arrastra desde la
# barra superior. Click en una herramienta = ver de qué robot era. Botón para equiparla.

const DB := preload("res://objetos_db.gd")

const COLUMNAS := 6
const FILAS_MINIMAS := 3
const TAM_SLOT := 72

const COL_FONDO := Color(0.11, 0.07, 0.04, 0.97)
const COL_BORDE := Color(0.95, 0.6, 0.15)
const COL_BORDE_SEL := Color(1.0, 0.9, 0.35)
const COL_SLOT := Color(0.2, 0.13, 0.07)
const COL_SLOT_EQUIPADO := Color(0.13, 0.3, 0.12)
const COL_SLOT_HOVER := Color(0.32, 0.21, 0.1)
const COL_TEXTO := Color(1.0, 0.85, 0.5)

# Lo asigna el autoload Inventario al crear esta ventana
var inventario: Node

var _ventana: PanelContainer
var _grid: GridContainer
var _info_titulo: Label
var _info_robot: Label
var _info_desc: Label
var _btn_equipar: Button
var _seleccionado: String = ""
var _arrastrando := false
var _offset := Vector2.ZERO

func _ready() -> void:
	layer = 101  # por encima del filtro retro y de los avisos
	_construir()
	visible = false
	inventario.objeto_agregado.connect(func(_id): _refrescar())
	inventario.equipado_cambiado.connect(func(_id): _refrescar())
	_refrescar()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("abrir_almacen"):
		visible = not visible
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- construcción

func _construir() -> void:
	_ventana = PanelContainer.new()
	_ventana.position = Vector2(110, 130)
	_ventana.add_theme_stylebox_override("panel", _caja(COL_FONDO, COL_BORDE, 4, 12))
	add_child(_ventana)

	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 12)
	_ventana.add_child(margen)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margen.add_child(vbox)

	# Barra superior (arrastrable)
	var barra := PanelContainer.new()
	barra.add_theme_stylebox_override("panel", _caja(Color(0.25, 0.15, 0.06), COL_BORDE, 2, 8))
	barra.gui_input.connect(_on_barra_input)
	vbox.add_child(barra)

	var hbox := HBoxContainer.new()
	barra.add_child(hbox)

	var titulo := Label.new()
	titulo.text = "  ALMACÉN DE HERRAMIENTAS"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 20)
	titulo.add_theme_color_override("font_color", COL_TEXTO)
	hbox.add_child(titulo)

	var cerrar := Button.new()
	cerrar.text = "X"
	cerrar.focus_mode = Control.FOCUS_NONE
	cerrar.add_theme_stylebox_override("normal", _caja(Color(0.7, 0.2, 0.15), COL_BORDE, 2, 6))
	cerrar.add_theme_stylebox_override("hover", _caja(Color(0.9, 0.3, 0.2), COL_BORDE_SEL, 2, 6))
	cerrar.add_theme_stylebox_override("pressed", _caja(Color(0.5, 0.1, 0.1), COL_BORDE, 2, 6))
	cerrar.pressed.connect(func(): visible = false)
	hbox.add_child(cerrar)

	# Cuadrícula de objetos
	var marco_grid := PanelContainer.new()
	marco_grid.add_theme_stylebox_override("panel", _caja(Color(0.07, 0.045, 0.03), COL_BORDE, 3, 10))
	vbox.add_child(marco_grid)

	var margen_grid := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen_grid.add_theme_constant_override("margin_" + lado, 10)
	marco_grid.add_child(margen_grid)

	_grid = GridContainer.new()
	_grid.columns = COLUMNAS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	margen_grid.add_child(_grid)

	# Panel de información
	var marco_info := PanelContainer.new()
	marco_info.custom_minimum_size = Vector2(0, 120)
	marco_info.add_theme_stylebox_override("panel", _caja(Color(0.07, 0.045, 0.03), COL_BORDE, 3, 10))
	vbox.add_child(marco_info)

	var margen_info := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen_info.add_theme_constant_override("margin_" + lado, 10)
	marco_info.add_child(margen_info)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	margen_info.add_child(info)

	_info_titulo = Label.new()
	_info_titulo.add_theme_font_size_override("font_size", 22)
	_info_titulo.add_theme_color_override("font_color", COL_BORDE_SEL)
	info.add_child(_info_titulo)

	_info_robot = Label.new()
	_info_robot.add_theme_font_size_override("font_size", 16)
	_info_robot.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	_info_robot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_info_robot)

	_info_desc = Label.new()
	_info_desc.add_theme_font_size_override("font_size", 15)
	_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_info_desc)

	_btn_equipar = Button.new()
	_btn_equipar.focus_mode = Control.FOCUS_NONE
	_btn_equipar.custom_minimum_size = Vector2(0, 38)
	_btn_equipar.add_theme_font_size_override("font_size", 18)
	_btn_equipar.add_theme_stylebox_override("normal", _caja(Color(0.75, 0.42, 0.08), COL_BORDE_SEL, 2, 8))
	_btn_equipar.add_theme_stylebox_override("hover", _caja(Color(0.95, 0.55, 0.12), COL_BORDE_SEL, 2, 8))
	_btn_equipar.add_theme_stylebox_override("pressed", _caja(Color(0.55, 0.3, 0.05), COL_BORDE_SEL, 2, 8))
	_btn_equipar.pressed.connect(_on_equipar_pressed)
	_btn_equipar.visible = false
	info.add_child(_btn_equipar)

# ------------------------------------------------------------------ contenido

func _refrescar() -> void:
	for hijo in _grid.get_children():
		_grid.remove_child(hijo)
		hijo.queue_free()

	var objetos: Array[String] = inventario.objetos
	var total := maxi(COLUMNAS * FILAS_MINIMAS, int(ceil(objetos.size() / float(COLUMNAS))) * COLUMNAS)
	for i in range(total):
		if i < objetos.size():
			_grid.add_child(_crear_slot(objetos[i]))
		else:
			_grid.add_child(_crear_slot_vacio())

	_mostrar_info()
	_ventana.reset_size.call_deferred()

func _crear_slot(id: String) -> Button:
	var datos: Dictionary = DB.obtener(id)
	var color_obj: Color = datos["color"]
	var borde := COL_BORDE_SEL if id == _seleccionado else COL_BORDE
	var fondo := COL_SLOT_EQUIPADO if id == inventario.equipado else COL_SLOT

	var b := Button.new()
	b.custom_minimum_size = Vector2(TAM_SLOT, TAM_SLOT)
	b.focus_mode = Control.FOCUS_NONE  # evita que las flechas del robot muevan el foco de la UI
	b.tooltip_text = str(datos["nombre"])
	b.add_theme_stylebox_override("normal", _caja(fondo, borde, 3, 8))
	b.add_theme_stylebox_override("hover", _caja(COL_SLOT_HOVER, COL_BORDE_SEL, 3, 8))
	b.add_theme_stylebox_override("pressed", _caja(COL_SLOT_HOVER, COL_BORDE_SEL, 3, 8))

	var ruta_icono := str(datos["icono"])
	if ruta_icono != "" and ResourceLoader.exists(ruta_icono):
		b.icon = load(ruta_icono)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		# Marcador temporal: inicial del nombre
		b.text = str(datos["nombre"]).substr(0, 1).to_upper()
		b.add_theme_font_size_override("font_size", 36)
		b.add_theme_color_override("font_color", color_obj)
		b.add_theme_color_override("font_hover_color", color_obj)
		b.add_theme_color_override("font_pressed_color", color_obj)

	b.pressed.connect(_seleccionar.bind(id))
	return b

func _crear_slot_vacio() -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(TAM_SLOT, TAM_SLOT)
	p.add_theme_stylebox_override("panel", _caja(Color(0.1, 0.065, 0.04), Color(0.4, 0.26, 0.1), 3, 8))
	return p

func _seleccionar(id: String) -> void:
	_seleccionado = id
	_refrescar()

func _mostrar_info() -> void:
	if _seleccionado == "" or not (_seleccionado in inventario.objetos):
		_info_titulo.text = "Selecciona un objeto"
		_info_robot.text = ""
		_info_desc.text = "Haz click en un cuadro para ver de qué robot era."
		_btn_equipar.visible = false
		return
	var datos: Dictionary = DB.obtener(_seleccionado)
	_info_titulo.text = str(datos["nombre"])
	_info_robot.text = "Pertenecía a: " + str(datos["robot"])
	_info_desc.text = str(datos["descripcion"])

	_btn_equipar.visible = bool(datos["equipable"])
	if inventario.equipado == _seleccionado:
		_btn_equipar.text = "Guardar herramienta (equipada)"
	else:
		_btn_equipar.text = "Equipar"

func _on_equipar_pressed() -> void:
	if inventario.equipado == _seleccionado:
		inventario.desequipar()
	else:
		inventario.equipar(_seleccionado)

# --------------------------------------------------------------- arrastre

func _on_barra_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = event.pressed
		_offset = _ventana.get_global_mouse_position() - _ventana.position
	elif event is InputEventMouseMotion and _arrastrando:
		var destino := _ventana.get_global_mouse_position() - _offset
		var pantalla := get_viewport().get_visible_rect().size
		destino.x = clampf(destino.x, 0.0, maxf(0.0, pantalla.x - _ventana.size.x))
		destino.y = clampf(destino.y, 0.0, maxf(0.0, pantalla.y - _ventana.size.y))
		_ventana.position = destino

# ------------------------------------------------------------------ estilo

func _caja(fondo: Color, borde: Color, grosor: int, radio: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(radio)
	return s
