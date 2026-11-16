extends Node3D
## Nivel Marte: Mision 03 (Mars Pathfinder + Sojourner) y Mision 04 (Opportunity).
## Convierte los objetos ya posicionados en la escena en zonas jugables.

const ZONA_POLVO := preload("res://Escenas/Interactuables/zona_polvo_lunar.tscn")
const ROCAS := preload("res://Escenas/Interactuables/rocas_snap27.tscn")
const S_INSTALAR := preload("res://Scripts/zona_instalar.gd")
const S_DESBLOQUEAR := preload("res://Scripts/zona_desbloquear.gd")
const S_BALIZA := preload("res://Scripts/baliza.gd")

const OBJ_M3 := ["petalo_instalado", "ruedas_instalado", "apxs_instalado"]
const OBJ_M4 := ["panel_delta_instalado", "brazo_idd_instalado", "mastil_instalado"]
const ARCHIVO_M3_SUB := "MARS PATHFINDER: THE FIRST FOOTPRINTS ON MARS\nA story of innovation, exploration, and discovery."
const ARCHIVO_M3 := "On July 4, 1997, the Mars Pathfinder mission landed in the Ares Vallis region, becoming one of the first major demonstrations of robotic exploration on the Martian surface.\n\nIts goal was to demonstrate that it was possible to land on Mars using a low-cost system and deploy a vehicle capable of studying the terrain.\n\nA DIFFERENT KIND OF LANDING\n\nPathfinder used an entry and descent system that included a heat shield, a parachute, and airbags to cushion the impact.\n\nOnce on the surface, it opened its three solar panels and began transmitting images and information about the landing site.\n\nThe lander also served as a communications station between Earth and Sojourner.\n\nTHE LITTLE EXPLORER\n\nOn July 6, 1997, Sojourner descended a ramp and began traveling around Pathfinder.\n\nIt had six wheels and a Rocker-Bogie suspension. Its cameras made it possible to observe the terrain and study rocks, while its APXS instrument analyzed the composition of the soil and Martian materials.\n\nBecause communications between Mars and Earth were delayed by 10 to 15 minutes, the rover also incorporated autonomous capabilities to avoid obstacles.\n\nTHE LEGACY OF PATHFINDER\n\nThe mission demonstrated that Mars could be explored using small, relatively inexpensive robotic vehicles.\n\nPathfinder and Sojourner transmitted images and scientific data until September 27, 1997, when communications were lost.\n\nAlthough their mission ended, their advances helped pave the way for the generations of rovers that would follow.\n\nA small vehicle. An entire planet to discover. The first footprints of a new era.\n\nAnd now, decades later, PATHFINDERS continues to preserve its legacy.\n\nEND OF HISTORICAL RECORD"
const ARCHIVO_M4_SUB := "OPPORTUNITY: BEYOND ITS MISSION\nA story of perseverance, discovery, and endurance."
const ARCHIVO_M4 := "Opportunity was one of two vehicles in the Mars Exploration Rover program, launched by NASA in 2003 and arriving on Mars in January 2004.\n\nIts objective was to investigate Martian geology, study the climate, and search for signs of environments that may have allowed water to exist in the past.\n\nAN OPPORTUNITY TO DISCOVER\n\nOn January 25, 2004, Opportunity arrived at Meridiani Terra, a region known for the presence of hematite, an iron-rich mineral that often forms in environments with water.\n\nThe rover was equipped with six wheels, solar panels, and various scientific instruments that allowed it to explore the terrain and study its materials.\n\nTECHNOLOGY FOR EXPLORATION\n\nIts solar panels supplied power to the electronic systems and stored electricity in rechargeable batteries.\n\nIts IDD robotic arm made it possible to bring instruments such as the APXS, the Mossbauer spectrometer, the microscopic imager, and the RAT tool close to the surfaces they needed to analyze.\n\nMeanwhile, the Pancam mast supported the panoramic and navigation cameras, allowing the rover to document landscapes and support scientific investigations.\n\nA MISSION THAT EXCEEDED ALL EXPECTATIONS\n\nOpportunity was designed for a mission much shorter than the one it ultimately managed to complete.\n\nHowever, it continued exploring Meridiani Terra for more than 14 years, sending photographs and scientific data to Earth.\n\nIts last communication was received on June 10, 2018.\n\nTHE LEGACY OF OPPORTUNITY\n\nOpportunity demonstrated that robotic explorers could far exceed their designers' expectations.\n\nIts long journey made it possible to study Mars for years and expand our knowledge of its geological history and ancient watery environments.\n\nA mission that was supposed to last months ended up leaving a mark that lasted more than a decade.\n\nAnd although its signal disappeared, its discoveries remain part of our history.\n\nEND OF HISTORICAL RECORD"

@onready var caja_texto = $CajaTexto

var _balizas: Array = []
var _balizas_activas := 0
var _pos_panel := Vector3.ZERO


func _ready() -> void:
	_crear_fade_in(1.5)
	var inventario := get_node("/root/Inventario")
	inventario.reiniciar()
	inventario.configurar_mision(OBJ_M3, "HISTORICAL ARCHIVE UNLOCKED", ARCHIVO_M3_SUB, ARCHIVO_M3)
	inventario.bloqueado = true
	_preparar_mision_3()
	_preparar_mision_4()
	inventario.mision_completada.connect(_on_mision_3_completa, CONNECT_ONE_SHOT)
	caja_texto.mostrar_textos([
		"MISSION CONTROL: \nSPARK, welcome to Mars.",
		"MISSION CONTROL: \nSPARK, you have arrived at Ares Vallis. A new chapter in the robotic exploration of Mars began here.",
		"MISSION 03: \nTHE FIRST FOOTPRINTS",
		"Main objective: \nRecover and preserve three historic components from the Mars Pathfinder lander and the Sojourner rover."
	])
	await caja_texto.textos_terminados
	inventario.bloqueado = false
	inventario.mostrar_aviso("Arrow keys: Move   [E] Use tool   [I] Inventory", 5.0)


# ------------------------------------------------------------ Mision 03

func _preparar_mision_3() -> void:
	_recogible_en("AntiStaticBrush", "escobilla")
	_recogible_en("Iman", "iman")
	_recogible_en("SteelChisel", "cincel")

	# Petalo solar cubierto de polvo marciano
	var petalo: Node3D = get_node("SolarPanelPetal")
	var polvo = ZONA_POLVO.instantiate()
	polvo.herramienta_requerida = "escobilla"
	polvo.mensaje = "Martian dust is covering a solar panel\nUse the anti-static brush"
	polvo.premio_escena = null
	polvo.premio_id = "petalo"
	polvo.add_to_group("guia")
	polvo.position = petalo.global_position
	add_child(polvo)
	_tenir(polvo.get_node("Monticulo"), Color(0.62, 0.33, 0.2))
	petalo.queue_free()

	# Derrumbe de rocas sobre el espectrometro APXS
	var apxs: Node3D = get_node("APXS Spectrometer")
	var rocas = ROCAS.instantiate()
	rocas.herramienta_requerida = "cincel"
	rocas.mensaje = "A rockfall is covering an instrument\nUse the steel chisel"
	rocas.accion_texto = "Break the rocks with the chisel"
	rocas.premio_escena = null
	rocas.premio_id = "apxs"
	rocas.add_to_group("guia")
	rocas.transform = Transform3D(Basis().scaled(Vector3.ONE * 1.3), apxs.global_position)
	add_child(rocas)
	rocas.get_node("PiezaOculta").hide()
	_tenir(rocas.get_node("Obstaculos"), Color(0.55, 0.3, 0.2))
	apxs.queue_free()

	_zona_instalar(get_node("PathfinderLander"), "Mars Pathfinder lander", 5.0,
		{"petalo": Vector3(2.6, 0.5, 0.0)}, {"petalo": Vector3(0, 0, -15)}, {"petalo": "side hinge"}, {"petalo": 3.0})
	_zona_instalar(get_node("Sojouner"), "Sojourner rover", 4.0,
		{"ruedas": Vector3(0, 0.1, 0), "apxs": Vector3(0, 1.2, -1.4)}, {}, {"ruedas": "chassis", "apxs": "rear mount"}, {"ruedas": 2.4, "apxs": 1.0})


func _on_mision_3_completa() -> void:
	var inventario := get_node("/root/Inventario")
	await inventario.esperar_ventanas()
	caja_texto.mostrar_textos([
		"MISSION COMPLETE",
		"MISSION CONTROL: \nSPARK, component recovery complete. Pathfinder and Sojourner have been restored.",
		"MISSION CONTROL: \nThe historical records are available. Beginning data recovery...",
		"NICO: \nFourteen years... That is a long time for a machine that was supposed to carry out a mission lasting only a few months.",
		"NICO: \nOpportunity kept exploring, even when many thought the end had already come.",
		"MISSION CONTROL: \nSPARK, we have located the Opportunity rover. Its last communication records were received in June 2018.",
		"MISSION 04: \nTO THE VERY LAST SIGNAL",
		"Main objective: \nRecover and preserve three historic components from the Opportunity rover (MER-B)."
	])
	await caja_texto.textos_terminados
	inventario.configurar_mision(OBJ_M4, "HISTORICAL ARCHIVE UNLOCKED", ARCHIVO_M4_SUB, ARCHIVO_M4)
	for b in _balizas:
		b.guia_habilitada = true
	inventario.mostrar_aviso("Activate the 3 telemetry beacons (0/3)", 4.0)
	if inventario.mision_terminada():
		_on_mision_4_completa()
	else:
		inventario.mision_completada.connect(_on_mision_4_completa, CONNECT_ONE_SHOT)


# ------------------------------------------------------------ Mision 04

func _preparar_mision_4() -> void:
	_recogible_en("Palanca", "palanca")
	_recogible_en("HeaterCartidge", "rhu")

	# Balizas de telemetria -> abren el compartimento del panel solar
	var panel: Node3D = get_node("PanelSolarDelta")
	_pos_panel = panel.global_position
	panel.queue_free()
	for area in get_node("TelemetryBeacons").get_children():
		if area is Area3D:
			var b = _nueva_zona(S_BALIZA, area.global_position, 3.0)
			b.activada.connect(_on_baliza_activada)
			_balizas.append(b)

	# Caja roja con el brazo IDD
	var brazo: Node3D = get_node("BrazoRoboticoIDD")
	var caja: Node3D = get_node("CajaDesatornillar")
	var z = _nueva_zona(S_DESBLOQUEAR, caja.global_position, 4.5)
	z.herramienta_requerida = "palanca"
	z.mensaje = "Red equipment box - sealed"
	z.accion_texto = "Force the box open with the lever"
	z.premio_id = "brazo_idd"
	z.altura_premio = 0.5
	z.texto_listo = "The box is open! Pick up the robotic arm"
	z.ocultar = [caja]
	brazo.queue_free()

	# Capsula congelada con el mastil Pancam
	var mastil: Node3D = get_node("MastilPanoramico")
	var capsula: Node3D = get_node("CapsulaCongelada")
	var c = _nueva_zona(S_DESBLOQUEAR, capsula.global_position, 4.5)
	c.item_requerido = "rhu"
	c.mensaje = "Frozen capsule - the lock is iced over"
	c.accion_texto = "Insert the RHU cartridge in the side slot"
	c.premio_id = "mastil"
	c.altura_premio = 0.5
	c.texto_listo = "The ice melts and the capsule opens!"
	c.ocultar = [capsula]
	mastil.queue_free()

	_zona_instalar(get_node("Opportuniyu/Area3D"), "Opportunity rover", 4.5,
		{"panel_delta": Vector3(0, 2.4, 0), "brazo_idd": Vector3(0, 1.2, 2.2), "mastil": Vector3(0.6, 2.6, 1.2)},
		{}, {"panel_delta": "upper deck", "brazo_idd": "front mount", "mastil": "vertical front neck"}, {"panel_delta": 3.6, "brazo_idd": 2.0, "mastil": 2.2})


func _on_baliza_activada() -> void:
	_balizas_activas += 1
	var inventario := get_node("/root/Inventario")
	inventario.mostrar_aviso("Telemetry beacons online: %d/3" % _balizas_activas, 3.0)
	if _balizas_activas < 3:
		return
	var compartimento: Node3D = get_node_or_null("MeshInstance3D")
	if compartimento:
		var t := create_tween()
		t.tween_property(compartimento, "position:y", compartimento.position.y + 3.0, 0.8)
		t.tween_property(compartimento, "scale", compartimento.scale * 0.01, 0.4)
		t.tween_callback(compartimento.queue_free)
		await t.finished
	var premio := _crear_recogible("panel_delta")
	premio.position = _pos_panel + Vector3.UP * 1.5
	add_child(premio)
	inventario.mostrar_aviso("3/3 - The compartment is open!\nPick up the solar panel", 3.5)


func _on_mision_4_completa() -> void:
	var inventario := get_node("/root/Inventario")
	await inventario.esperar_ventanas()
	caja_texto.mostrar_textos([
		"MISSION COMPLETE",
		"MISSION CONTROL: \nSPARK, all three components have been successfully recovered and installed.",
		"MISSION CONTROL: \nWe have restored Opportunity's historical configuration. The latest scientific records are available. Beginning recovery...",
		"MISSION CONTROL: \nThis time, we are not recovering a rover, but a machine that managed to leave the Martian ground.",
		"MISSION CONTROL: \nComplete the restoration of its components and preserve its story. Good luck, SPARK."
	])


# ------------------------------------------------------------ Utilidades

func _nueva_zona(script: Script, pos: Vector3, radio: float) -> Area3D:
	var area := Area3D.new()
	area.set_script(script)
	var forma := CollisionShape3D.new()
	forma.shape = CylinderShape3D.new()
	forma.shape.radius = radio
	forma.shape.height = 5.0
	forma.position = Vector3.UP * 1.5
	area.add_child(forma)
	area.position = pos
	add_child(area)
	return area


func _zona_instalar(robot: Node3D, nombre: String, radio: float, inst: Dictionary, rot: Dictionary, lugares: Dictionary, tamanos: Dictionary = {}) -> void:
	var area := Area3D.new()
	area.set_script(S_INSTALAR)
	area.nombre_robot = nombre
	area.instalaciones = inst
	area.rotaciones = rot
	area.lugares = lugares
	area.tamanos = tamanos
	var forma := CollisionShape3D.new()
	forma.shape = CylinderShape3D.new()
	forma.shape.radius = radio
	forma.shape.height = 5.0
	forma.position = Vector3.UP * 1.5
	area.add_child(forma)
	robot.add_child(area)


## Reemplaza un objeto estatico de la escena por un recogible del Inventario.
func _recogible_en(nombre_nodo: String, id: String) -> void:
	var nodo: Node3D = get_node_or_null(nombre_nodo)
	if nodo == null:
		push_warning("NivelMarte: no existe el nodo %s" % nombre_nodo)
		return
	var premio := _crear_recogible(id)
	premio.position = nodo.global_position + Vector3.UP * 1.0
	add_child(premio)
	nodo.queue_free()


func _crear_recogible(id: String) -> Area3D:
	var area := Area3D.new()
	area.set_script(load("res://Scripts/objeto_recogible.gd"))
	area.item_id = id
	area.add_to_group("objeto_clave")
	var inventario := get_node("/root/Inventario")
	var ruta: String = inventario.modelo_de(id)
	if ruta != "" and ResourceLoader.exists(ruta):
		var modelo: Node3D = load(ruta).instantiate()
		var caja: AABB = inventario.calcular_aabb(modelo)
		var escala := 1.6 / maxf(caja.size[caja.get_longest_axis_index()], 0.01)
		modelo.scale = Vector3.ONE * escala
		modelo.position = -caja.get_center() * escala
		area.add_child(modelo)
	var forma := CollisionShape3D.new()
	forma.shape = SphereShape3D.new()
	forma.shape.radius = 1.5
	area.add_child(forma)
	return area


func _tenir(raiz: Node, color: Color) -> void:
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 1.0
		n.material_override = m


func _crear_fade_in(duracion: float) -> void:
	var capa_transicion = CanvasLayer.new()
	capa_transicion.layer = 10
	add_child(capa_transicion)
	var fondo_negro = ColorRect.new()
	fondo_negro.color = Color(0, 0, 0, 1)
	fondo_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_transicion.add_child(fondo_negro)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fondo_negro, "color:a", 0.0, duracion)
	tween.tween_callback(capa_transicion.queue_free)
