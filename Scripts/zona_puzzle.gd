extends "res://Scripts/zona_interaccion.gd"
## Zona que, con la herramienta equipada, abre un puzzle de popup_kit.
## Al resolverlo quita los nodos de "ocultar" y suelta la pieza.

@export var popup_scene: PackedScene
@export var premio_id := ""
@export var altura_premio: float = 1.6
## Nodos que se quitan al resolver (los asigna el nivel o la escena).
var ocultar: Array = []


func _init() -> void:
	ajustar_al_suelo = false


func _al_iniciar() -> void:
	add_to_group("guia")


func es_guia_activa() -> bool:
	return not esta_completada() and Inventario.tiene(herramienta_requerida)


func _usar() -> void:
	await animar_herramienta(herramienta_requerida, 1.0)
	var popup = PopupManager.open(popup_scene, {"source": self})
	popup.solved.connect(_on_resuelto)
	await popup.closed


func _on_resuelto() -> void:
	completar()
	await PopupManager.popup_closed
	for n in ocultar:
		if is_instance_valid(n):
			var t := create_tween()
			t.tween_property(n, "position", n.position + Vector3(2.5, 1.5, 0), 0.4)
			t.tween_property(n, "scale", n.scale * 0.01, 0.3)
			t.tween_callback(n.queue_free)
	await get_tree().create_timer(0.7).timeout
	soltar_premio(null, altura_premio, premio_id)
	Inventario.mostrar_aviso("The scrap is gone! Pick up the wheels", 2.5)
