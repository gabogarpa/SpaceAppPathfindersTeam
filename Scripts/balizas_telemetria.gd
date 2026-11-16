extends Node3D
## Grupo de balizas de telemetría. Al encender todas (de rojo a verde) se abre el
## compartimento y la pieza que guarda queda libre para recogerla.

signal compartimento_abierto

## Nodo que tapa la pieza (se eleva y desaparece al abrirse).
@export var compartimento: NodePath
## Objeto recogible (bloqueado = true) guardado en el compartimento.
@export var pieza: NodePath

var _balizas: Array = []
var _encendidas := 0


func _ready() -> void:
	for n in find_children("*", "Area3D", true, false):
		if n.has_signal("completada") and n.has_method("encendida"):
			_balizas.append(n)
			n.completada.connect(_on_baliza_encendida)


func balizas_apagadas() -> Array:
	return _balizas.filter(func(b): return not b.encendida())


func abierto() -> bool:
	return _encendidas >= _balizas.size() and not _balizas.is_empty()


func _on_baliza_encendida() -> void:
	_encendidas += 1
	Inventario.mostrar_aviso("Telemetry beacons: %d/%d" % [_encendidas, _balizas.size()], 3.0)
	if abierto():
		_abrir()


func _abrir() -> void:
	await get_tree().create_timer(1.0).timeout
	Inventario.mostrar_aviso("Telemetry beacons: %d/%d\nThe compartment is opening!" % [_encendidas, _balizas.size()], 3.5)
	var tapa := get_node_or_null(compartimento) as Node3D
	if tapa:
		for c in tapa.find_children("*", "CollisionShape3D", true, false):
			c.set_deferred("disabled", true)
		var t := create_tween().set_parallel(true)
		t.tween_property(tapa, "position:y", tapa.position.y + 5.0, 1.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(tapa, "scale", tapa.scale * 0.01, 1.0).set_delay(0.8)
		await t.finished
		tapa.hide()
	var recogible := get_node_or_null(pieza)
	if recogible and recogible.has_method("liberar"):
		recogible.liberar()
	compartimento_abierto.emit()
