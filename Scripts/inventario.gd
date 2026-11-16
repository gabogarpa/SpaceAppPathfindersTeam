extends Node
## Autoload "Inventario": guarda los objetos del jugador, la herramienta equipada
## y dibuja el HUD (avisos + ventana de inventario).
## Registrar en Project Settings > Globals > Autoload con el nombre "Inventario".

signal item_agregado(id: String)
signal herramienta_equipada(id: String)
signal inventario_toggled(abierto: bool)
## Se emite cuando se completan todos los objetivos de la mision actual.
signal mision_completada
## Se emite al cerrar la ultima ventana de informacion de la cola.
signal ventanas_cerradas

const ACCION_INVENTARIO := "inventario"
const ACCION_USAR := "usar_herramienta"
const TECLA_INVENTARIO := KEY_I
const TECLA_USAR := KEY_E
const RUTA_FUENTE := "res://Fonts/UFO50Tall.ttf"

## Catálogo de objetos. Agrega aquí nuevas piezas o herramientas.
## "ficha" = ventana de información que aparece al conseguir la pieza.
var ITEMS := {
	"escoba": {
		"nombre": "Broom",
		"modelo": "res://Models/Objetos/Escoba_Voxel.glb",
		"herramienta": true,
		"robot": "SPARK (MoonBot) - Pathfinders",
		"uso": "Sweeps away lunar dust to uncover buried parts.",
	},
	"brazo_robotico": {
		"nombre": "Robotic Arm",
		"modelo": "res://Models/Objetos/Brazo_Excavador_Voxel.glb",
		"herramienta": true,
		"robot": "Surveyor 3 (1967)",
		"uso": "Dug, collected and moved lunar soil to study the regolith. SPARK uses it to move scrap and rocks and to lift objects.",
		"ficha_titulo": "ITEM 1 - Sampling Arm (Surveyor 3)",
		"ficha_texto": "This approximately 1.5-meter pantograph arm supported a small scoop designed to handle lunar soil.\n\nIts purpose was to dig, collect, and move material from the surface, allowing scientists to observe how lunar regolith behaved.\n\nDuring its mission, the sampler operated for 18 hours and 22 minutes, digging trenches up to 18 centimeters deep.\n\nIts operations provided information about the strength, texture, and structure of the lunar soil.",
	},
	"bateria": {
		"nombre": "Battery Cell",
		"modelo": "res://Models/Objetos/Bateria_Portatil_Voxel.glb",
		"icono": "res://Models/Objetos/Bateria.png",
		"herramienta": false,
		"robot": "Apollo 12 (1969) - television camera",
		"uso": "Power cell for the television camera.",
	},
	"camara_tv": {
		"nombre": "Television Camera",
		"modelo": "res://Models/Objetos/Camara_Westinghouse_Voxel.glb",
		"icono": "res://Models/Objetos/Camara.png",
		"herramienta": false,
		"robot": "Apollo 12 (1969)",
		"uso": "Broadcast video of the operations on the lunar surface.",
		"ficha_titulo": "ITEM 2 - Television Camera (Apollo 12)",
		"ficha_texto": "This equipment was part of Apollo 12's television system, intended for the mission's operations on the lunar surface.\n\nDuring installation, the camera was accidentally pointed at the Sun. The exposure damaged its vidicon tube, leaving it completely inoperable.\n\nAlthough it could not perform its function during the mission, this component represents one of the technical challenges the astronauts faced during their exploration.",
	},
	"snap27": {
		"nombre": "SNAP-27 Generator",
		"modelo": "res://Models/Objetos/SNAP27_ALSEP_Voxel.glb",
		"herramienta": false,
		"robot": "Apollo 12 (1969) - ALSEP station",
		"uso": "Generated electricity for the scientific instruments of the central station.",
		"ficha_titulo": "ITEM 3 - SNAP-27 Thermoelectric Generator (Apollo 12)",
		"ficha_texto": "The SNAP-27 was a radioisotope thermoelectric generator that provided the power needed to keep the ALSEP scientific station operating.\n\nIt used a plutonium-238 capsule that generated heat through radioactive decay. An array of 442 thermoelectric couples converted that heat directly into electricity.\n\nThe generator produced approximately 70 watts of direct current at 16 volts, supplying power to the scientific instruments at the central station.\n\nWithout this power supply system, the experiments would not have been able to continue operating on the lunar surface.",
	},
	"escobilla": {
		"nombre": "Anti-Static Brush",
		"modelo": "res://Models/Objetos/MISSION 03 THE FIRST FOOTPRINTS/Anti-Static Brush.glb",
		"herramienta": true,
		"robot": "SPARK (MoonBot) - Pathfinders",
		"uso": "Removes Martian dust without damaging solar cells.",
	},
	"iman": {
		"nombre": "High-Power Magnet",
		"modelo": "res://Models/Objetos/Iman_Alta_Potencia_Voxel.glb",
		"herramienta": true,
		"robot": "SPARK (MoonBot) - Pathfinders",
		"uso": "Pulls metal scrap away from buried parts.",
	},
	"cincel": {
		"nombre": "Steel Chisel",
		"modelo": "res://Models/Objetos/MISSION 03 THE FIRST FOOTPRINTS/Steel Chisel.glb",
		"herramienta": true,
		"robot": "SPARK (MoonBot) - Pathfinders",
		"uso": "Breaks apart rockfalls and hard rock.",
	},
	"palanca": {
		"nombre": "Metal Lever",
		"modelo": "res://Models/Objetos/MISSION 04 THE VERY LAST SIGNAL/Metal Lever.glb",
		"herramienta": true,
		"robot": "SPARK (MoonBot) - Pathfinders",
		"uso": "Forces open stuck or sealed containers.",
	},
	"rhu": {
		"nombre": "RHU Heater Cartridge",
		"modelo": "res://Models/Objetos/MISSION 04 THE VERY LAST SIGNAL/RHU_Heater_Cartridge_Voxel.glb",
		"herramienta": false,
		"robot": "Radioisotope Heater Unit",
		"uso": "Keeps electronics warm in the Martian cold.",
	},
	"petalo": {
		"nombre": "Solar Panel Petal",
		"modelo": "res://Models/Objetos/MISSION 03 THE FIRST FOOTPRINTS/Solar Panel Petal (Mars Pathfinder).glb",
		"herramienta": false,
		"robot": "Mars Pathfinder (1997)",
		"uso": "Supplied power to the lander together with its batteries.",
		"ficha_titulo": "ITEM 1 - Solar Panel Petal (Mars Pathfinder)",
		"ficha_texto": "Pathfinder had three triangular metal solar panels, known as petals, which unfolded after landing.\n\nTheir solar cells, with a total surface area of more than 2.5 square meters, supplied power to the lander in combination with rechargeable batteries.\n\nIn addition to powering its systems, Pathfinder used its equipment to observe Sojourner's operations and transmit its data to Earth.",
	},
	"ruedas": {
		"nombre": "Rocker-Bogie Wheel System",
		"modelo": "res://Models/Objetos/MISSION 03 THE FIRST FOOTPRINTS/Wheel System and Rocker-Bogie Suspension (Sojourner).glb",
		"herramienta": false,
		"robot": "Sojourner (1997)",
		"uso": "Six-wheel mobility system with rocker-bogie suspension.",
		"ficha_titulo": "ITEM 2 - Six-Wheel System and Rocker-Bogie Suspension (Sojourner)",
		"ficha_texto": "Sojourner was a small six-wheeled vehicle equipped with a suspension system known as rocker-bogie.\n\nThis design was part of its mobility system and allowed it to travel across the Martian surface while exploring the rocks and terrain around Pathfinder.\n\nIts movements also provided information about soil properties through the study of its tracks and the behavior of its wheels.",
	},
	"apxs": {
		"nombre": "APXS Spectrometer",
		"modelo": "res://Models/Objetos/MISSION 03 THE FIRST FOOTPRINTS/APXS Spectrometer (Sojourner).glb",
		"herramienta": false,
		"robot": "Sojourner (1997)",
		"uso": "Analyzed the composition of Martian rocks and soil.",
		"ficha_titulo": "ITEM 3 - APXS Spectrometer (Sojourner)",
		"ficha_texto": "RECOVERED RECORD: APXS SPECTROMETER\n\nThe Alpha Particle X-ray Spectrometer (APXS) was one of Sojourner's scientific instruments.\n\nIts purpose was to analyze the composition of Martian rocks and soil, providing information about the materials present on the surface.\n\nImages of the analyzed samples were also transmitted to Earth to facilitate their study.\n\nThanks to this instrument, Sojourner could do more than travel across Mars: it could also investigate what the planet was made of.",
	},
	"panel_delta": {
		"nombre": "Solar Panel Array",
		"modelo": "res://Models/Objetos/MISSION 04 THE VERY LAST SIGNAL/Nueva carpeta/Solar Panel Array (Opportunity).glb",
		"herramienta": false,
		"robot": "Opportunity (2004)",
		"uso": "Generated up to 140 watts to power the rover.",
		"ficha_titulo": "ITEM 1 - Solar Panel Array (Opportunity)",
		"ficha_texto": "Opportunity used an array of solar panels distributed across its upper deck, extending out to the sides like a pair of wings.\n\nUnder full sunlight, they could generate up to 140 watts of power. This electricity was stored in two rechargeable batteries to power the rover's systems.\n\nTheir operation was essential for keeping the electronic equipment and scientific instruments active during the exploration of Mars.",
	},
	"brazo_idd": {
		"nombre": "IDD Robotic Arm",
		"modelo": "res://Models/Objetos/MISSION 04 THE VERY LAST SIGNAL/Nueva carpeta/IDD Robotic Arm and RAT Tool (Opportunity).glb",
		"herramienta": false,
		"robot": "Opportunity (2004)",
		"uso": "Brought scientific instruments and the RAT drill to rocks and soil.",
		"ficha_titulo": "ITEM 2 - IDD Robotic Arm and RAT Tool (Opportunity)",
		"ficha_texto": "The Instrument Deployment Device (IDD) was an articulated arm located at the front of the rover.\n\nVarious scientific instruments were mounted at its end, including the APXS spectrometer, the Mossbauer spectrometer, the microscopic imager, and the Rock Abrasion Tool (RAT).\n\nThis system made it possible to bring the instruments close to materials of interest and conduct investigations directly on Martian rocks and soil.",
	},
	"mastil": {
		"nombre": "Pancam Panoramic Mast",
		"modelo": "res://Models/Objetos/MISSION 04 THE VERY LAST SIGNAL/Nueva carpeta/Pancam Panoramic Mast (Opportunity).glb",
		"herramienta": false,
		"robot": "Opportunity (2004)",
		"uso": "Held the panoramic and navigation cameras.",
		"ficha_titulo": "ITEM 3 - Pancam Panoramic Mast (Opportunity)",
		"ficha_texto": "The Pancam mast was located on top of the rover and supported the panoramic and navigation cameras.\n\nPositioned approximately 1.4 meters above the wheel base, these cameras made it possible to capture images of the surroundings and document the places explored.\n\nThe mast also served as a periscope for the Miniature Thermal Emission Spectrometer (Mini-TES), another of the rover's scientific instruments.",
	}
}

## Objetivos de la misión. Al completarlos todos se abre el archivo histórico.
const OBJETIVOS := ["brazo_robotico", "camara", "estacion"]

const ARCHIVO_TITULO := "HISTORICAL ARCHIVE UNLOCKED"
const ARCHIVO_SUBTITULO := "APOLLO 12: THE MEETING OF TWO GENERATIONS\nA story of exploration, science, and collaboration."
const ARCHIVO_TEXTO := """On April 20, 1967, Surveyor 3 landed in Oceanus Procellarum with the goal of studying the lunar terrain and demonstrating that robotic spacecraft could operate on the surface.

One of its notable instruments was a sampling arm that could dig into and manipulate the soil. During its mission, it transmitted 6,326 photographs and gathered information about the strength, texture, and structure of the lunar regolith.

THE MEETING WITH INTREPID

On November 19, 1969, Apollo 12's lunar module Intrepid landed about 180 meters from Surveyor 3. Astronauts Pete Conrad and Alan Bean arrived to study the surface, collect samples, and deploy scientific experiments.

While its television camera was being installed, it was accidentally pointed at the Sun, damaging its vidicon tube and rendering it unusable.

The following day, the astronauts visited Surveyor 3 and recovered approximately 10 kilograms of components, including its camera, to examine them on Earth. This made it possible to study how the materials had withstood more than two years on the Moon.

THE ENERGY THAT KEPT SCIENCE ALIVE

Apollo 12 also deployed the ALSEP scientific station, whose operation depended on the SNAP-27 generator.

This device converted the heat produced by plutonium-238 into electricity, powering the scientific instruments and allowing them to transmit their measurements to Earth.

Thanks to these experiments, researchers were able to study seismic activity, the magnetic field, lunar dust, the atmosphere, and particles coming from the Sun.

The station remained operational until September 30, 1977, when it was shut down along with the other ALSEP stations.

THE LEGACY OF A MISSION

Surveyor 3 helped pave the way for human exploration. Apollo 12 built on those advances and returned to study the remains of one of the first robotic explorers.

One machine paved the way for human beings. Human beings returned to learn more about that machine.

Two different missions. One shared story of exploration.

And now, decades later, PATHFINDERS continues that legacy."""

var items: Array[String] = []
var equipada := ""
var abierto := false
## true mientras no se debe interactuar (p. ej. durante el texto de introduccion).
var bloqueado := false

var _capa: CanvasLayer
var _aviso_panel: PanelContainer
var _aviso_label: Label
var _equipada_panel: PanelContainer
var _equipada_nombre: Label
var _equipada_detalle: Label
var _equipada_vista: SubViewportContainer
var _equipada_pivote: Node3D
var _ventana: Control
var _grid: GridContainer
var _info_label: Label
var _fuente: Font
var _previews: Array[Node3D] = []
var _prev_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _prev_paused := false
var _aviso_id := 0
var objetivos_completados: Array[String] = []
## Mision actual (cada nivel puede cambiarla con configurar_mision()).
var objetivos: Array = OBJETIVOS.duplicate()
var archivo_titulo := ARCHIVO_TITULO
var archivo_subtitulo := ARCHIVO_SUBTITULO
var archivo_texto := ARCHIVO_TEXTO
var _cola_ventanas: Array[Dictionary] = []
var _ventana_info: Control
var _ventana_info_abierta := false
var _pausa_previa_info := false
var _mouse_previo_info := Input.MOUSE_MODE_VISIBLE


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
	_actualizar_equipada()
	herramienta_equipada.emit(id)


func nombre_de(id: String) -> String:
	return ITEMS.get(id, {}).get("nombre", id)


func modelo_de(id: String) -> String:
	return ITEMS.get(id, {}).get("modelo", "")


func robot_de(id: String) -> String:
	return ITEMS.get(id, {}).get("robot", "")


func uso_de(id: String) -> String:
	return ITEMS.get(id, {}).get("uso", "")


## Texto con robot y uso de un objeto.
func descripcion_de(id: String) -> String:
	var lineas: Array[String] = []
	if robot_de(id) != "":
		lineas.append("Robot: %s" % robot_de(id))
	if uso_de(id) != "":
		lineas.append("Use: %s" % uso_de(id))
	return "\n".join(lineas)


func icono_de(id: String) -> String:
	return ITEMS.get(id, {}).get("icono", "")


func tiene_ficha(id: String) -> bool:
	return ITEMS.get(id, {}).has("ficha_texto")


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
	if abierto or _ventana_info_abierta:
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
	_equipada_panel.hide()
	_ventana.show()
	inventario_toggled.emit(true)


func cerrar() -> void:
	if not abierto:
		return
	abierto = false
	_ventana.hide()
	_equipada_panel.visible = equipada != "" and not _ventana_info_abierta
	get_tree().paused = _prev_paused
	Input.mouse_mode = _prev_mouse_mode
	inventario_toggled.emit(false)


func alternar() -> void:
	if abierto:
		cerrar()
	else:
		abrir()


# ---------------------------------------------------------------- Fichas / misión

## Muestra la ventana de información de una pieza (objeto + texto a un lado).
func mostrar_ficha(id: String) -> void:
	if not tiene_ficha(id):
		return
	var item: Dictionary = ITEMS[id]
	mostrar_ventana_info("PIECE RECOVERED", item.ficha_titulo, item.ficha_texto, id)


func completar_objetivo(id: String) -> void:
	if objetivos_completados.has(id):
		return
	objetivos_completados.append(id)
	if mision_terminada():
		if archivo_texto != "":
			mostrar_ventana_info(archivo_titulo, archivo_subtitulo, archivo_texto, "")
		mision_completada.emit()


func mision_terminada() -> bool:
	return objetivos.all(func(o): return objetivos_completados.has(o))


## Cambia la mision actual: objetivos a completar y archivo historico final.
func configurar_mision(nuevos_objetivos: Array, titulo: String, subtitulo: String, texto: String) -> void:
	objetivos = nuevos_objetivos.duplicate()
	archivo_titulo = titulo
	archivo_subtitulo = subtitulo
	archivo_texto = texto


## Vacia el inventario (p. ej. al llegar a un planeta nuevo).
func reiniciar() -> void:
	items.clear()
	objetivos_completados.clear()
	equipar("")
	ocultar_aviso()


## Espera a que no quede ninguna ventana de informacion abierta.
func esperar_ventanas() -> void:
	await get_tree().process_frame
	while _ventana_info_abierta or not _cola_ventanas.is_empty():
		await ventanas_cerradas


## Ventana con un modelo 3D girando a la izquierda y texto a la derecha.
## Si ya hay una abierta, se pone en cola.
func mostrar_ventana_info(encabezado: String, titulo: String, texto: String, id_modelo: String) -> void:
	_cola_ventanas.append({"encabezado": encabezado, "titulo": titulo, "texto": texto, "id": id_modelo})
	if not _ventana_info_abierta:
		_abrir_siguiente_ventana()


func ventana_info_abierta() -> bool:
	return _ventana_info_abierta


func _abrir_siguiente_ventana() -> void:
	if _cola_ventanas.is_empty():
		return
	var popups := get_node_or_null("/root/PopupManager")
	if popups and popups.has_method("is_open") and popups.is_open():
		await popups.popup_closed
	if abierto:
		cerrar()
	var datos: Dictionary = _cola_ventanas.pop_front()
	_ventana_info_abierta = true
	_pausa_previa_info = get_tree().paused
	_mouse_previo_info = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ocultar_aviso()
	_equipada_panel.hide()
	_construir_ventana_info(datos)


func _cerrar_ventana_info() -> void:
	if not _ventana_info_abierta:
		return
	_ventana_info_abierta = false
	_ventana_info.queue_free()
	_ventana_info = null
	_previews.clear()
	get_tree().paused = _pausa_previa_info
	Input.mouse_mode = _mouse_previo_info
	_equipada_panel.visible = equipada != ""
	if not _cola_ventanas.is_empty():
		_abrir_siguiente_ventana.call_deferred()
	else:
		ventanas_cerradas.emit()


func _construir_ventana_info(datos: Dictionary) -> void:
	_ventana_info = Control.new()
	_ventana_info.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capa.add_child(_ventana_info)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ventana_info.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ventana_info.add_child(centro)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel(0.92))
	centro.add_child(panel)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var con_modelo: bool = datos.id != ""
	if con_modelo:
		var marco := PanelContainer.new()
		var estilo := _estilo_panel(0.4)
		estilo.bg_color = Color(0.03, 0.08, 0.14, 1)
		marco.add_theme_stylebox_override("panel", estilo)
		marco.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(marco)
		var contenedor := SubViewportContainer.new()
		contenedor.stretch = true
		contenedor.custom_minimum_size = Vector2(220, 220)
		marco.add_child(contenedor)
		contenedor.add_child(crear_preview(datos.id, Vector2i(220, 220)))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	hbox.add_child(vbox)
	var enc := _label(datos.encabezado, 22)
	enc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	enc.modulate = Color(0.0, 0.85, 1.0)
	vbox.add_child(enc)
	var tit := _label(datos.titulo, 26)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tit.custom_minimum_size.x = 440 if con_modelo else 680
	vbox.add_child(tit)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440 if con_modelo else 680, 380 if con_modelo else 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var cuerpo := _label(datos.texto, 18)
	cuerpo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(cuerpo)
	var boton := Button.new()
	boton.text = "Continue [Enter]"
	boton.focus_mode = Control.FOCUS_NONE
	boton.size_flags_horizontal = Control.SIZE_SHRINK_END
	if _fuente:
		boton.add_theme_font_override("font", _fuente)
	boton.add_theme_font_size_override("font_size", 22)
	boton.pressed.connect(_cerrar_ventana_info)
	vbox.add_child(boton)


# ---------------------------------------------------------------- Input

func _unhandled_input(event: InputEvent) -> void:
	if _ventana_info_abierta:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_cerrar_ventana_info()
			get_viewport().set_input_as_handled()
		return
	if bloqueado and not abierto:
		return
	if event.is_action_pressed(ACCION_INVENTARIO):
		alternar()
		get_viewport().set_input_as_handled()
	elif abierto and event.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if is_instance_valid(_equipada_pivote):
		_equipada_pivote.rotate_y(delta * 1.5)
	if abierto or _ventana_info_abierta:
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
	_aviso_label = _label("", 24)
	_aviso_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso_label.custom_minimum_size.x = 560
	_aviso_panel.add_child(_aviso_label)

	# Herramienta equipada (abajo a la derecha, girando)
	_equipada_panel = PanelContainer.new()
	_equipada_panel.add_theme_stylebox_override("panel", _estilo_panel(0.75))
	_equipada_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equipada_panel.anchor_left = 1.0
	_equipada_panel.anchor_top = 1.0
	_equipada_panel.anchor_right = 1.0
	_equipada_panel.anchor_bottom = 1.0
	_equipada_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_equipada_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_equipada_panel.offset_right = -16
	_equipada_panel.offset_bottom = -16
	_equipada_panel.hide()
	_capa.add_child(_equipada_panel)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equipada_panel.add_child(fila)
	_equipada_vista = SubViewportContainer.new()
	_equipada_vista.stretch = true
	_equipada_vista.custom_minimum_size = Vector2(130, 130)
	_equipada_vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(_equipada_vista)
	var textos := VBoxContainer.new()
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_child(textos)
	var titulo := _label("EQUIPPED", 16)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titulo.modulate = Color(0.0, 0.85, 1.0)
	textos.add_child(titulo)
	_equipada_nombre = _label("", 26)
	_equipada_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	textos.add_child(_equipada_nombre)
	_equipada_detalle = _label("", 16)
	_equipada_detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_equipada_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equipada_detalle.custom_minimum_size.x = 280
	textos.add_child(_equipada_detalle)

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
	vbox.add_child(_label("INVENTORY", 36))
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(_grid)
	_info_label = _label("", 20)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(620, 110)
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	_info_label.text = _texto_ayuda_inventario()


func _crear_slot(id: String, cantidad: int) -> Control:
	var boton := Button.new()
	boton.custom_minimum_size = Vector2(140, 160)
	boton.toggle_mode = true
	boton.focus_mode = Control.FOCUS_NONE
	if id == "":
		boton.disabled = true
		return boton
	boton.button_pressed = id == equipada
	boton.pressed.connect(_on_slot_pressed.bind(id))
	boton.mouse_entered.connect(_mostrar_info_item.bind(id))
	boton.mouse_exited.connect(func(): _info_label.text = _texto_ayuda_inventario())

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(vbox)

	var contenedor := SubViewportContainer.new()
	contenedor.stretch = true
	contenedor.custom_minimum_size = Vector2(140, 110)
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(contenedor)
	contenedor.add_child(crear_preview(id))

	var texto := nombre_de(id)
	if cantidad > 1:
		texto += " x%d" % cantidad
	if id == equipada:
		texto += "\n(equipped)"
	var l := _label(texto, 20)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(l)
	return boton


## SubViewport con el modelo 3D del objeto (para íconos y fichas).
func crear_preview(id: String, tam := Vector2i(150, 120)) -> SubViewport:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = tam
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


func _actualizar_equipada() -> void:
	for c in _equipada_vista.get_children():
		c.queue_free()
	_equipada_pivote = null
	if equipada == "":
		_equipada_panel.hide()
		return
	var vp := crear_preview(equipada, Vector2i(130, 130))
	_equipada_pivote = vp.get_child(0)
	_previews.erase(_equipada_pivote)
	_equipada_vista.add_child(vp)
	_equipada_nombre.text = nombre_de(equipada)
	_equipada_detalle.text = "%s\n[%s] Use   [%s] Inventory" % [
		descripcion_de(equipada), tecla_de(ACCION_USAR), tecla_de(ACCION_INVENTARIO)]
	_equipada_panel.show()


func _mostrar_info_item(id: String) -> void:
	var extra := "\n(click to equip)" if es_herramienta(id) else ""
	_info_label.text = "%s\n%s%s" % [nombre_de(id), descripcion_de(id), extra]


func _texto_ayuda_inventario() -> String:
	return "Hover over an item to see its information\nClick a tool to equip it - [%s] Close" % tecla_de(ACCION_INVENTARIO)


func _on_slot_pressed(id: String) -> void:
	if not es_herramienta(id):
		mostrar_aviso("%s is not a tool" % nombre_de(id), 2.0)
	elif equipada == id:
		equipar("")
	else:
		equipar(id)
		mostrar_aviso("%s equipped" % nombre_de(id), 1.5)
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
