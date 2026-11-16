extends "res://Scripts/zona_interaccion.gd"
## Contenedor bloqueado (caja, capsula...). Con la herramienta equipada o el objeto
## requerido se abre, los nodos de "ocultar" desaparecen y suelta la pieza.

## Objeto que se consume al usarlo (p. ej. "rhu"). Vacio = solo herramienta.
@export var item_requerido := ""
@export var premio_id := ""
@export var altura_premio: float = 1.6
@export var texto_listo := "You found something inside!"

## Nodos que se sacuden y desaparecen al abrir (los asigna el nivel).
var ocultar: Array = []


func _init() -> void:
	ajustar_al_suelo = false


func _al_iniciar() -> void:
	add_to_group("guia")


func es_guia_activa() -> bool:
	if esta_completada():
		return false
	if item_requerido != "":
		return Inventario.tiene(item_requerido)
	return herramienta_requerida != "" and Inventario.tiene(herramienta_requerida)


func _requisito_faltante() -> String:
	if item_requerido != "" and not Inventario.tiene(item_requerido):
		return "You need: %s" % Inventario.nombre_de(item_requerido)
	return ""


func _usar() -> void:
	completar()
	if item_requerido != "":
		Inventario.quitar(item_requerido)
	var fin: Signal
	if herramienta_requerida != "":
		fin = animar_herramienta(herramienta_requerida, 1.4)
	else:
		fin = get_tree().create_timer(1.2).timeout
	for n in ocultar:
		if not is_instance_valid(n):
			continue
		var t := create_tween()
		var r: Vector3 = n.rotation
		for i in 4:
			t.tween_property(n, "rotation:z", r.z + 0.12, 0.08)
			t.tween_property(n, "rotation:z", r.z - 0.12, 0.08)
		t.tween_property(n, "scale", n.scale * 0.01, 0.4)
		t.tween_callback(n.queue_free)
	await fin
	soltar_premio(null, altura_premio, premio_id)
	Inventario.mostrar_aviso(texto_listo, 2.5)
