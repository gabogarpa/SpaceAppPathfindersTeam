extends "res://Scripts/zona_interaccion.gd"
## Zona que abre un popup de puzzle (p. ej. quitar la chatarra con el imán).
## Al resolverlo, los obstáculos desaparecen y la pieza tapada queda libre.

@export var popup_scene: PackedScene
## Objeto recogible (bloqueado = true) que queda libre al resolver el puzzle.
@export var pieza: NodePath
@export var aviso_final := "The component is free!"

@onready var obstaculos: Node3D = get_node_or_null("Obstaculos")


func _usar() -> void:
	await animar_herramienta(herramienta_requerida, 0.8)
	var popup = PopupManager.open(popup_scene, {"source": self})
	popup.solved.connect(_on_resuelto, CONNECT_ONE_SHOT)
	await popup.closed


func _on_resuelto() -> void:
	completar()
	await PopupManager.popup_closed
	if obstaculos:
		# Los restos salen disparados hacia arriba, atraídos por el imán.
		var t := create_tween().set_parallel(true)
		t.tween_property(obstaculos, "position:y", obstaculos.position.y + 4.0, 0.8) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(obstaculos, "scale", Vector3.ONE * 0.01, 0.8).set_delay(0.2)
		t.tween_property(obstaculos, "rotation:y", obstaculos.rotation.y + TAU, 0.8)
		await t.finished
		obstaculos.hide()
	var recogible := get_node_or_null(pieza)
	if recogible and recogible.has_method("liberar"):
		recogible.liberar()
	Inventario.mostrar_aviso(aviso_final, 2.5)
