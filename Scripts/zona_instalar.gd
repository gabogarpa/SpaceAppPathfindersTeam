extends "res://Scripts/zona_interaccion.gd"
## Robot historico donde se instalan las piezas recuperadas (Pathfinder, Sojourner, Opportunity).
## Cada pieza se encaja en su posicion local; al instalarla cuenta como objetivo "<id>_instalado".

signal pieza_instalada(id: String)

## id del Inventario -> posicion local donde se encaja la pieza.
@export var instalaciones := {}
## id -> rotacion en grados de la pieza instalada.
@export var rotaciones := {}
## id -> nombre del lugar (p. ej. "side hinge").
@export var lugares := {}
@export var tam_pieza: float = 1.4
## id -> tamano de la pieza instalada (si no, tam_pieza).
@export var tamanos := {}
@export var nombre_robot := ""

var _instaladas: Array = []


func _init() -> void:
	ajustar_al_suelo = false
	es_objetivo = false


func _al_iniciar() -> void:
	add_to_group("guia")


func es_guia_activa() -> bool:
	return _pieza_disponible() != ""


func _pieza_disponible() -> String:
	for id in instalaciones:
		if not _instaladas.has(id) and Inventario.tiene(id):
			return id
	return ""


func _requisito_faltante() -> String:
	if _pieza_disponible() != "":
		return ""
	var faltan: Array[String] = []
	for id in instalaciones:
		if not _instaladas.has(id):
			faltan.append(Inventario.nombre_de(id))
	return "Missing parts: %s" % ", ".join(faltan)


func _actualizar_aviso() -> void:
	var id := _pieza_disponible()
	mensaje = nombre_robot
	if id != "":
		accion_texto = "Install %s (%s)" % [Inventario.nombre_de(id), lugares.get(id, "")]
	super._actualizar_aviso()


func _usar() -> void:
	var id := _pieza_disponible()
	if id == "":
		return
	Inventario.quitar(id)
	_instaladas.append(id)
	var ruta: String = Inventario.modelo_de(id)
	if ruta != "" and ResourceLoader.exists(ruta):
		var pivote := Node3D.new()
		add_child(pivote)
		var modelo: Node3D = load(ruta).instantiate()
		var caja: AABB = Inventario.calcular_aabb(modelo)
		var escala: float = tamanos.get(id, tam_pieza) / maxf(caja.size[caja.get_longest_axis_index()], 0.01)
		modelo.scale = Vector3.ONE * escala
		modelo.position = -caja.get_center() * escala
		pivote.add_child(modelo)
		pivote.rotation_degrees = rotaciones.get(id, Vector3.ZERO)
		var destino: Vector3 = instalaciones[id]
		pivote.position = destino + Vector3.UP * 2.5
		var t := create_tween()
		t.tween_property(pivote, "position", destino, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await t.finished
	Inventario.mostrar_aviso("%s installed on %s!" % [Inventario.nombre_de(id), nombre_robot], 3.0)
	pieza_instalada.emit(id)
	if _instaladas.size() == instalaciones.size():
		completar()
	Inventario.completar_objetivo(id + "_instalado")
