extends "res://Scripts/zona_interaccion.gd"
## Robot histórico al que se le instalan piezas (Pathfinder, Sojourner, Opportunity).
## Con alguna de sus piezas en el inventario, [E] abre el esquema del robot y la pieza
## se arrastra a su lugar. Al instalarla se muestra su ficha y se completa su objetivo
## ("<id>_instalado").

signal pieza_instalada(id: String)

const VENTANA := preload("res://Escenas/UI/ventana_montaje.tscn")

## Nombre del robot que aparece en el esquema.
@export var titulo := ""
## Foto o esquema del robot.
@export var imagen: Texture2D
## Una entrada por pieza: {"id": item_id, "etiqueta": "SIDE HINGE", "pos": Vector2(0..1, 0..1)}
## "pos" es el punto de la imagen donde va la pieza (proporcional al tamaño de la imagen).
## Opcional "caja": Vector2 con el centro del recuadro, si no cabe encima del punto.
@export var slots: Array[Dictionary] = []

var instaladas: Array[String] = []
var _nuevas: Array[String] = []


func _init() -> void:
	herramienta_requerida = ""
	accion_texto = "Open schematic and install components"
	ajustar_al_suelo = false
	es_objetivo = false


func ids_piezas() -> Array[String]:
	var ids: Array[String] = []
	for s in slots:
		ids.append(String(s.id))
	return ids


func pendientes() -> Array[String]:
	return ids_piezas().filter(func(id): return not instaladas.has(id))


## true si el jugador lleva alguna pieza que falta en este robot.
func tiene_pieza_para_instalar() -> bool:
	return pendientes().any(func(id): return Inventario.tiene(id))


func _requisito_faltante() -> String:
	if tiene_pieza_para_instalar():
		return ""
	var nombres: Array[String] = []
	for id in pendientes():
		nombres.append(Inventario.nombre_de(id))
	return "Missing: %s" % ", ".join(nombres)


func _usar() -> void:
	_nuevas.clear()
	var popup = PopupManager.open(VENTANA, {"source": self})
	await popup.closed
	for id in _nuevas:
		Inventario.mostrar_ficha(id, "PIECE INSTALLED")
	for id in _nuevas:
		Inventario.completar_objetivo(id + "_instalado")
	_nuevas.clear()


## Lo llama la ventana del esquema al encajar una pieza en su lugar.
func instalar(id: String) -> void:
	if instaladas.has(id):
		return
	instaladas.append(id)
	_nuevas.append(id)
	Inventario.quitar(id)
	_destello()
	pieza_instalada.emit(id)
	if pendientes().is_empty():
		completar()


func _destello() -> void:
	var luz := OmniLight3D.new()
	luz.light_color = Color(0.4, 0.9, 1.0)
	luz.omni_range = 8.0
	luz.light_energy = 0.0
	luz.position = Vector3.UP * 2.0
	add_child(luz)
	var t := create_tween()
	t.tween_property(luz, "light_energy", 6.0, 0.25)
	t.tween_property(luz, "light_energy", 0.0, 0.9)
	t.tween_callback(luz.queue_free)
