extends "res://Scripts/zona_interaccion.gd"
## Pila de obstáculos (placas de chatarra, rocas...) que tapan una pieza.
## Con el brazo robótico equipado, los obstáculos salen volando hacia los lados
## y la pieza queda flotando para recogerla.

## Escena del objeto que aparece al apartar los obstáculos.
@export var premio_escena: PackedScene
@export var altura_premio: float = 1.2
@export var duracion: float = 1.6
## Qué tan lejos se apartan los obstáculos.
@export var distancia_apartar: float = 2.8

@onready var obstaculos: Node3D = $Obstaculos
## Modelo decorativo de la pieza asomándose debajo de los obstáculos.
@onready var pieza_oculta: Node3D = get_node_or_null("PiezaOculta")
@onready var particulas: CPUParticles3D = get_node_or_null("Particulas")


func _init() -> void:
	herramienta_requerida = "brazo_robotico"
	mensaje = "Use the robotic arm"


func _al_iniciar() -> void:
	if particulas:
		particulas.emitting = false


func _usar() -> void:
	completar()
	var brazo := animar_herramienta(herramienta_requerida, duracion)
	await get_tree().create_timer(duracion * 0.3).timeout
	if particulas:
		particulas.emitting = true
	var i := 0
	var hijos := obstaculos.get_children()
	for o in hijos:
		if o is Node3D:
			_apartar(o, i, hijos.size())
			i += 1
			await get_tree().create_timer(0.08).timeout
	await brazo
	if particulas:
		particulas.emitting = false
	if pieza_oculta:
		var t := create_tween()
		t.tween_property(pieza_oculta, "scale", Vector3.ONE * 0.01, 0.3)
		t.tween_callback(pieza_oculta.hide)
	soltar_premio(premio_escena, altura_premio)
	Inventario.mostrar_aviso("You found something underneath!", 2.5)


func _apartar(o: Node3D, indice: int, total: int) -> void:
	var dir := Vector3(o.position.x, 0, o.position.z)
	if dir.length() < 0.2:
		var ang := TAU * float(indice) / maxf(total, 1)
		dir = Vector3(cos(ang), 0, sin(ang))
	dir = dir.normalized()
	var destino := o.position + dir * (distancia_apartar + randf() * 0.8)
	destino.y = 0.05
	var arriba := (o.position + destino) * 0.5 + Vector3.UP * 1.6
	var t := create_tween().set_parallel(true)
	var tiempo := 0.7
	t.tween_property(o, "position", arriba, tiempo * 0.5).set_ease(Tween.EASE_OUT)
	t.tween_property(o, "position", destino, tiempo * 0.5).set_ease(Tween.EASE_IN).set_delay(tiempo * 0.5)
	t.tween_property(o, "rotation", o.rotation + Vector3(randf_range(-1, 1), randf_range(-2, 2), randf_range(-1, 1)), tiempo)
