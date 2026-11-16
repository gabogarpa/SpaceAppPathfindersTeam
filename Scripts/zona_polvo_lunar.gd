extends "res://Scripts/zona_interaccion.gd"
## Montículo de polvo lunar con una pieza enterrada.
## El jugador equipa la escoba y la usa: el polvo desaparece, queda un pequeño
## cráter y la pieza aparece flotando.

signal excavado

## Escena del objeto que aparece al limpiar el polvo (p. ej. brazo_robotico.tscn).
@export var premio_escena: PackedScene
## Alternativa a premio_escena: id del Inventario para crear el recogible en código.
@export var premio_id := ""
@export var altura_premio: float = 1.3
@export var duracion_barrido: float = 1.4

@onready var monticulo: Node3D = $Monticulo
@onready var crater: Node3D = $Crater
@onready var particulas: CPUParticles3D = $Particulas


func _init() -> void:
	herramienta_requerida = "escoba"
	mensaje = "Use the broom"
	guia = "polvo"


func es_guia_activa() -> bool:
	return not esta_completada() and Inventario.tiene(herramienta_requerida)


func _al_iniciar() -> void:
	crater.hide()
	particulas.emitting = false


func _usar() -> void:
	completar()
	particulas.emitting = true
	var t := create_tween().set_parallel(true)
	t.tween_property(monticulo, "scale", Vector3(0.6, 0.02, 0.6), duracion_barrido) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(monticulo, "position:y", -0.5, duracion_barrido)
	await animar_herramienta(herramienta_requerida, duracion_barrido)
	if t.is_running():
		await t.finished

	particulas.emitting = false
	monticulo.hide()
	crater.scale = Vector3.ONE * 0.4
	crater.show()
	create_tween().tween_property(crater, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	soltar_premio(premio_escena, altura_premio, premio_id)
	Inventario.mostrar_aviso("You found something buried!", 2.5)
	excavado.emit()
