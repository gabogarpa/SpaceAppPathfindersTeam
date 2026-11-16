extends RefCounted
# Información de cada objeto del juego.
# Para agregar uno nuevo, añade una entrada con su id (el mismo id_objeto de su escena recogible).
#
# "icono":    ruta a una imagen, por ejemplo "res://Iconos/escoba.png". Vacío = muestra la inicial.
# "equipable": true si es una herramienta que se puede equipar y usar. false si es una pieza.

const DATOS := {
	"escoba": {
		"nombre": "Escoba",
		"robot": "BARRE-O, robot de mantenimiento lunar",
		"descripcion": "Cepillo que usaba para barrer el polvo lunar de las rutas y paneles. Sirve para despejar zonas cubiertas de polvo.",
		"icono": "",
		"color": Color(0.95, 0.78, 0.25),
		"equipable": true,
	},
	"brazo_robotico": {
		"nombre": "Brazo robótico",
		"robot": "ARM-7, robot de carga",
		"descripcion": "Brazo articulado con garra. Estaba enterrado bajo el polvo lunar. Podría servir para mover objetos pesados.",
		"icono": "",
		"color": Color(0.7, 0.75, 0.8),
		"equipable": false,
	},
	"taladro": {
		"nombre": "Taladro",
		"robot": "PERFORA-X, robot minero",
		"descripcion": "Taladro de impacto que usaba para abrir roca y muros. Sirve para romper paredes frágiles.",
		"icono": "",
		"color": Color(0.55, 0.75, 0.95),
		"equipable": true,
	},
}

static func obtener(id: String) -> Dictionary:
	if DATOS.has(id):
		return DATOS[id]
	# Objeto sin datos registrados: muestra algo razonable en vez de fallar
	return {
		"nombre": id.capitalize(),
		"robot": "Robot desconocido",
		"descripcion": "Sin información registrada.",
		"icono": "",
		"color": Color(0.8, 0.8, 0.8),
		"equipable": false,
	}
