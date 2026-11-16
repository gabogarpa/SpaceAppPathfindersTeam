extends Node3D
## Nivel de Marte.
##   Misión 03 (Pathfinder / Sojourner) -> Misión 04 (Opportunity).
## Cada pieza: conseguir la herramienta -> despejar la zona -> recoger la pieza ->
## instalarla en su robot (esquema con arrastrar y soltar). Las piezas se pueden
## hacer en cualquier orden; la misión termina al instalar las tres.

const OBJETIVOS_M03 := ["petalo_solar_instalado", "rocker_bogie_instalado", "apxs_instalado"]
const OBJETIVOS_M04 := ["panel_solar_delta_instalado", "brazo_idd_instalado", "mastil_pancam_instalado"]

const TEXTO_INTRO_M03 := [
	"MISSION CONTROL: \nSPARK, welcome to Mars.",
	"MISSION CONTROL: \nSPARK, you have arrived at Ares Vallis. A new chapter in the robotic exploration of Mars began here.",
	"MISSION 03: \nTHE FIRST FOOTPRINTS",
	"Main objective: \nRecover and preserve three historic components from the Mars Pathfinder lander and the Sojourner rover.",
]
const TEXTO_FIN_M03 := [
	"MISSION COMPLETE",
	"MISSION CONTROL: \nSPARK, component recovery complete. Pathfinder and Sojourner have been restored.",
	"MISSION CONTROL: \nThe historical records are available. Beginning data recovery...",
]
const TEXTO_INTRO_M04 := [
	"NICO: \nFourteen years...",
	"NICO: \nThat is a long time for a machine that was supposed to carry out a mission lasting only a few months.",
	"NICO: \nOpportunity kept exploring, even when many thought the end had already come.",
	"MISSION CONTROL: \nSPARK, we have located the Opportunity rover. Its last communication records were received in June 2018.",
	"MISSION 04: \nTO THE VERY LAST SIGNAL",
	"Main objective: \nRecover and preserve three historic components from the Opportunity rover (MER-B).",
]
const TEXTO_FIN_M04 := [
	"MISSION COMPLETE",
	"MISSION CONTROL: \nSPARK, all three components have been successfully recovered and installed.",
	"MISSION CONTROL: \nWe have restored Opportunity's historical configuration.",
	"MISSION CONTROL: \nThe latest scientific records are available. Beginning recovery...",
]
const TEXTO_SIGUIENTE := [
	"MISSION CONTROL: \nThis time, we are not recovering a rover, but a machine that managed to leave the Martian ground.",
	"MISSION CONTROL: \nComplete the restoration of its components and preserve its story.",
	"MISSION CONTROL: \nGood luck, SPARK.",
]

const ARCHIVO_TITULO := "HISTORICAL ARCHIVE UNLOCKED"
const ARCHIVO_M03_SUBTITULO := "MARS PATHFINDER: THE FIRST FOOTPRINTS ON MARS\nA story of innovation, exploration, and discovery."
const ARCHIVO_M03_TEXTO := """On July 4, 1997, the Mars Pathfinder mission landed in the Ares Vallis region, becoming one of the first major demonstrations of robotic exploration on the Martian surface.

Its goal was to demonstrate that it was possible to land on Mars using a low-cost system and deploy a vehicle capable of studying the terrain.

A DIFFERENT KIND OF LANDING

Pathfinder used an entry and descent system that included a heat shield, a parachute, and airbags to cushion the impact.

Once on the surface, it opened its three solar panels and began transmitting images and information about the landing site.

The lander also served as a communications station between Earth and Sojourner.

THE LITTLE EXPLORER

On July 6, 1997, Sojourner descended a ramp and began traveling around Pathfinder.

It had six wheels and a Rocker-Bogie suspension. Its cameras made it possible to observe the terrain and study rocks, while its APXS instrument analyzed the composition of the soil and Martian materials.

Because communications between Mars and Earth were delayed by 10 to 15 minutes, the rover also incorporated autonomous capabilities to avoid obstacles.

THE LEGACY OF PATHFINDER

The mission demonstrated that Mars could be explored using small, relatively inexpensive robotic vehicles.

Pathfinder and Sojourner transmitted images and scientific data until September 27, 1997, when communications were lost.

Although their mission ended, their advances helped pave the way for the generations of rovers that would follow.

A small vehicle. An entire planet to discover. The first footprints of a new era.

And now, decades later, PATHFINDERS continues to preserve its legacy.

END OF HISTORICAL RECORD"""
const ARCHIVO_M04_SUBTITULO := "OPPORTUNITY: BEYOND ITS MISSION\nA story of perseverance, discovery, and endurance."
const ARCHIVO_M04_TEXTO := """Opportunity was one of two vehicles in the Mars Exploration Rover program, launched by NASA in 2003 and arriving on Mars in January 2004.

Its objective was to investigate Martian geology, study the climate, and search for signs of environments that may have allowed water to exist in the past.

AN OPPORTUNITY TO DISCOVER

On January 25, 2004, Opportunity arrived at Meridiani Terra, a region known for the presence of hematite, an iron-rich mineral that often forms in environments with water.

The rover was equipped with six wheels, solar panels, and various scientific instruments that allowed it to explore the terrain and study its materials.

TECHNOLOGY FOR EXPLORATION

Its solar panels supplied power to the electronic systems and stored electricity in rechargeable batteries.

Its IDD robotic arm made it possible to bring instruments such as the APXS, the Mössbauer spectrometer, the microscopic imager, and the RAT tool close to the surfaces they needed to analyze.

Meanwhile, the Pancam mast supported the panoramic and navigation cameras, allowing the rover to document landscapes and support scientific investigations.

A MISSION THAT EXCEEDED ALL EXPECTATIONS

Opportunity was designed for a mission much shorter than the one it ultimately managed to complete.

However, it continued exploring Meridiani Terra for more than 14 years, sending photographs and scientific data to Earth.

Its last communication was received on June 10, 2018.

THE LEGACY OF OPPORTUNITY

Opportunity demonstrated that robotic explorers could far exceed their designers' expectations.

Its long journey made it possible to study Mars for years and expand our knowledge of its geological history and ancient watery environments.

A mission that was supposed to last months ended up leaving a mark that lasted more than a decade.

And although its signal disappeared, its discoveries remain part of our history.

END OF HISTORICAL RECORD"""

@onready var caja_texto = $CajaTexto
@onready var mision03: Node3D = $Mision03
@onready var mision04: Node3D = $Mision04

## Pasos de cada pieza para el radar: herramienta -> zona -> pieza -> robot.
@onready var _piezas_m03 := [
	{"id": "petalo_solar", "herramienta": "escobilla", "recogible_herramienta": $Mision03/AntiStaticBrush,
		"zona": $Mision03/PolvoPetalo, "pieza": $Mision03/SolarPanelPetal, "robot": $Mision03/PathfinderLander},
	{"id": "rocker_bogie", "herramienta": "iman", "recogible_herramienta": $Mision03/Iman,
		"zona": $Mision03/RockerBoogie, "pieza": $Mision03/RockerBoogie/Pieza, "robot": $Mision03/Sojouner},
	{"id": "apxs", "herramienta": "cincel", "recogible_herramienta": $Mision03/SteelChisel,
		"zona": $Mision03/DerrumbeRocas, "pieza": get_node("Mision03/APXS Spectrometer"), "robot": $Mision03/Sojouner},
]
@onready var _piezas_m04 := [
	{"id": "panel_solar_delta", "balizas": $Mision04/TelemetryBeacons,
		"pieza": $Mision04/PanelSolarDelta, "robot": $Mision04/Opportuniyu/Area3D},
	{"id": "brazo_idd", "herramienta": "palanca", "recogible_herramienta": $Mision04/Palanca/Area3D,
		"zona": $Mision04/CajaEquipo, "pieza": $Mision04/BrazoRoboticoIDD, "robot": $Mision04/Opportuniyu/Area3D},
	{"id": "mastil_pancam", "herramienta": "cartucho_rhu", "recogible_herramienta": $Mision04/HeaterCartidge/Area3D,
		"zona": $Mision04/CapsulaCongelada, "pieza": $Mision04/MastilPanoramico, "robot": $Mision04/Opportuniyu/Area3D},
]

## 3 o 4 = misión en juego. 0 = textos/transición. 5 = Marte terminado.
var _mision := 0


func _ready() -> void:
	_crear_fade_in(1.5)
	Inventario.reiniciar()
	Inventario.iniciar_mision(OBJETIVOS_M03)
	Inventario.mision_completada.connect(_on_mision_completada)
	_activar_mision(mision04, false)
	await _mostrar_textos(TEXTO_INTRO_M03)
	_mision = 3
	Inventario.mostrar_aviso("Arrow keys: Move   [E] Use tool   [I] Inventory", 5.0)


## Muestra textos que se pasan con Enter (el juego queda en pausa) cuando no hay
## otra ventana abierta.
func _mostrar_textos(lineas: Array) -> void:
	await Inventario.esperar_ventanas_info()
	caja_texto.mostrar_textos(lineas)
	await caja_texto.textos_terminados


func _mostrar_archivo(subtitulo: String, texto: String) -> void:
	Inventario.mostrar_ventana_info(ARCHIVO_TITULO, subtitulo, texto, "")
	await Inventario.esperar_ventanas_info()


func _on_mision_completada() -> void:
	match _mision:
		3:
			_mision = 0
			await _mostrar_textos(TEXTO_FIN_M03)
			await _mostrar_archivo(ARCHIVO_M03_SUBTITULO, ARCHIVO_M03_TEXTO)
			Inventario.reiniciar()
			Inventario.iniciar_mision(OBJETIVOS_M04)
			await _mostrar_textos(TEXTO_INTRO_M04)
			_activar_mision(mision04, true)
			_mision = 4
			Inventario.mostrar_aviso("Find the Opportunity rover and its missing components", 4.0)
		4:
			_mision = 0
			await _mostrar_textos(TEXTO_FIN_M04)
			await _mostrar_archivo(ARCHIVO_M04_SUBTITULO, ARCHIVO_M04_TEXTO)
			Inventario.reiniciar()
			await _mostrar_textos(TEXTO_SIGUIENTE)
			_mision = 5


## Una misión desactivada no se ve ni detecta al robot.
func _activar_mision(nodo: Node3D, activa: bool) -> void:
	nodo.visible = activa
	nodo.process_mode = Node.PROCESS_MODE_INHERIT if activa else Node.PROCESS_MODE_DISABLED


## Lo usa el radar (sonda_localizadora.gd): siguiente paso de cada pieza pendiente.
func objetivos_guia() -> Array:
	var piezas: Array
	match _mision:
		3:
			piezas = _piezas_m03
		4:
			piezas = _piezas_m04
		_:
			return []
	var resultado := []
	for p in piezas:
		var paso = _siguiente_paso(p)
		if paso is Array:
			resultado.append_array(paso)
		elif paso != null:
			resultado.append(paso)
	return resultado


func _siguiente_paso(p: Dictionary) -> Variant:
	var id: String = p.id
	if p.robot.instaladas.has(id):
		return null
	if Inventario.tiene(id):
		return p.robot
	if is_instance_valid(p.pieza) and not p.pieza.bloqueado:
		return p.pieza
	if p.has("balizas"):
		return p.balizas.balizas_apagadas()
	if not p.zona.esta_completada():
		if Inventario.tiene(p.herramienta):
			return p.zona
		if is_instance_valid(p.recogible_herramienta):
			return p.recogible_herramienta
	return null


func _crear_fade_in(duracion: float) -> void:
	var capa_transicion = CanvasLayer.new()
	capa_transicion.layer = 10 
	add_child(capa_transicion)
	
	var fondo_negro = ColorRect.new()
	fondo_negro.color = Color(0, 0, 0, 1) # Empieza en negro total
	fondo_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_transicion.add_child(fondo_negro)
	
	# El fade sigue aunque el juego esté en pausa por el texto de introducción
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fondo_negro, "color:a", 0.0, duracion)
	tween.tween_callback(capa_transicion.queue_free)
