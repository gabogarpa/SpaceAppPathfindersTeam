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
## Cómo desaparecen los obstáculos: apartar (salen volando), barrer (se aplanan),
## romper (se hacen pedazos) o derretir (brillan y se deshacen).
@export_enum("apartar", "barrer", "romper", "derretir") var modo := "apartar"
## Objeto recogible ya colocado en el nivel (con bloqueado = true) que queda libre
## al despejar la zona. Si está vacío se usa premio_escena.
@export var pieza: NodePath
## La herramienta se gasta al usarla (p. ej. un cartucho que se inserta).
@export var consumir_herramienta := false
@export var aviso_final := "You found something underneath!"

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
			match modo:
				"barrer":
					_barrer(o)
				"romper":
					_romper(o)
				"derretir":
					_derretir(o)
				_:
					_apartar(o, i, hijos.size())
			i += 1
			await get_tree().create_timer(0.08).timeout
	await brazo
	if modo != "apartar":
		await get_tree().create_timer(0.5).timeout
	if consumir_herramienta:
		Inventario.quitar(herramienta_requerida)
	if particulas:
		particulas.emitting = false
	if pieza_oculta:
		var t := create_tween()
		t.tween_property(pieza_oculta, "scale", Vector3.ONE * 0.01, 0.3)
		t.tween_callback(pieza_oculta.hide)
	var recogible := get_node_or_null(pieza)
	if recogible and recogible.has_method("liberar"):
		recogible.liberar()
	else:
		soltar_premio(premio_escena, altura_premio)
	Inventario.mostrar_aviso(aviso_final, 2.5)


func _barrer(o: Node3D) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(o, "scale", Vector3(o.scale.x * 0.6, 0.01, o.scale.z * 0.6), duracion * 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(o, "position:y", o.position.y - 0.4, duracion * 0.6)
	t.chain().tween_callback(o.hide)


func _romper(o: Node3D) -> void:
	var t := create_tween()
	var base := o.position
	for k in 4:
		t.tween_property(o, "position", base + Vector3(randf_range(-0.12, 0.12), 0, randf_range(-0.12, 0.12)), 0.05)
	t.tween_property(o, "position", base, 0.05)
	var dir := Vector3(base.x, 0, base.z)
	if dir.length() < 0.2:
		dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	dir = dir.normalized()
	t.set_parallel(true)
	t.tween_property(o, "position", base + dir * 1.2 + Vector3.UP * 0.6, 0.35).set_ease(Tween.EASE_OUT)
	t.tween_property(o, "scale", Vector3.ONE * 0.01, 0.4).set_ease(Tween.EASE_IN)
	t.tween_property(o, "rotation", o.rotation + Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3)), 0.4)
	t.chain().tween_callback(o.hide)


func _derretir(o: Node3D) -> void:
	var t := create_tween()
	for m in [o] + o.find_children("*", "MeshInstance3D", true, false):
		if m is GeometryInstance3D:
			var mat := StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = Color(0.7, 0.9, 1.0, 0.75)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.45, 0.1)
			mat.emission_energy_multiplier = 0.0
			m.material_override = mat
			t.parallel().tween_property(mat, "emission_energy_multiplier", 3.0, duracion * 0.5)
			t.parallel().tween_property(mat, "albedo_color:a", 0.0, duracion).set_delay(duracion * 0.4)
	t.parallel().tween_property(o, "scale", o.scale * Vector3(0.9, 0.05, 0.9), duracion).set_delay(duracion * 0.4)
	t.tween_callback(o.hide)


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
