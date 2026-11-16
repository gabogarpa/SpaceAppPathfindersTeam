extends Area3D
## Montículo de polvo lunar con una pieza enterrada.
## El jugador se acerca, equipa la herramienta desde el inventario y la usa:
## el polvo desaparece, queda un pequeño cráter y la pieza aparece flotando.

signal excavado

@export var herramienta_requerida := "escoba"
## Escena del objeto que aparece al limpiar el polvo (p. ej. brazo_robotico.tscn).
@export var premio_escena: PackedScene
@export var altura_premio: float = 1.3
@export var mensaje := "Usa la escoba"
@export var duracion_barrido: float = 1.4
## Al iniciar, baja/sube la zona hasta tocar el terreno.
@export var ajustar_al_suelo := true

@onready var monticulo: Node3D = $Monticulo
@onready var crater: Node3D = $Crater
@onready var particulas: CPUParticles3D = $Particulas

var _jugador: Node3D = null
var _excavado := false


func _ready() -> void:
	add_to_group("objeto_clave")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Inventario.herramienta_equipada.connect(_actualizar_aviso.unbind(1))
	Inventario.item_agregado.connect(_actualizar_aviso.unbind(1))
	crater.hide()
	particulas.emitting = false
	if ajustar_al_suelo:
		await get_tree().physics_frame
		_colocar_en_suelo()


func _on_body_entered(body: Node3D) -> void:
	if _excavado or not _es_jugador(body):
		return
	_jugador = body
	_actualizar_aviso()


func _on_body_exited(body: Node3D) -> void:
	if body != _jugador:
		return
	_jugador = null
	if not _excavado:
		Inventario.ocultar_aviso()


func _actualizar_aviso() -> void:
	if _jugador == null or _excavado:
		return
	var herramienta: String = Inventario.nombre_de(herramienta_requerida).to_lower()
	var detalle: String
	if Inventario.equipada == herramienta_requerida:
		detalle = "[%s] Usar %s" % [Inventario.tecla_de(Inventario.ACCION_USAR), herramienta]
	elif Inventario.tiene(herramienta_requerida):
		detalle = "[%s] Abrir inventario y equipar %s" % [Inventario.tecla_de(Inventario.ACCION_INVENTARIO), herramienta]
	else:
		detalle = "Necesitas encontrar una %s" % herramienta
	Inventario.mostrar_aviso("%s\n%s" % [mensaje, detalle])


func _unhandled_input(event: InputEvent) -> void:
	if _excavado or _jugador == null:
		return
	if event.is_action_pressed(Inventario.ACCION_USAR):
		get_viewport().set_input_as_handled()
		if Inventario.equipada == herramienta_requerida:
			_excavar()
		else:
			_actualizar_aviso()


func _excavar() -> void:
	_excavado = true
	remove_from_group("objeto_clave")
	Inventario.ocultar_aviso()

	var herramienta := _crear_herramienta_visual()
	particulas.emitting = true

	var t := create_tween().set_parallel(true)
	t.tween_property(monticulo, "scale", Vector3(0.6, 0.02, 0.6), duracion_barrido) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(monticulo, "position:y", -0.5, duracion_barrido)
	if herramienta:
		var barrido := create_tween().set_loops(4)
		var paso := duracion_barrido / 8.0
		barrido.tween_property(herramienta, "rotation:z", deg_to_rad(35), paso)
		barrido.tween_property(herramienta, "rotation:z", deg_to_rad(-35), paso)
	await t.finished

	particulas.emitting = false
	monticulo.hide()
	if herramienta:
		herramienta.queue_free()
	crater.scale = Vector3.ONE * 0.4
	crater.show()
	create_tween().tween_property(crater, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_soltar_premio()
	Inventario.mostrar_aviso("Encontraste algo enterrado!", 2.5)
	excavado.emit()


func _soltar_premio() -> void:
	if premio_escena == null:
		return
	var premio: Node3D = premio_escena.instantiate()
	premio.position = Vector3(0, altura_premio, 0)
	if "retraso_recogida" in premio:
		premio.retraso_recogida = 1.0
	if "ajustar_al_suelo" in premio:
		premio.ajustar_al_suelo = false
	premio.scale = Vector3.ONE * 0.01
	add_child(premio)
	create_tween().tween_property(premio, "scale", Vector3.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Modelo temporal de la herramienta que "barre" el montículo.
func _crear_herramienta_visual() -> Node3D:
	var ruta: String = Inventario.modelo_de(herramienta_requerida)
	if ruta == "" or not ResourceLoader.exists(ruta):
		return null
	var pivote := Node3D.new()
	add_child(pivote)
	var lado := Vector3.BACK
	if _jugador:
		var d := _jugador.global_position - global_position
		d.y = 0.0
		if d.length() > 0.1:
			lado = d.normalized()
	pivote.global_position = global_position + lado * 0.9 + Vector3.UP * 0.2
	pivote.look_at(global_position + Vector3.UP * 0.2, Vector3.UP)
	var modelo: Node3D = load(ruta).instantiate()
	modelo.scale = Vector3.ONE * 0.6
	modelo.rotation_degrees.x = -35
	pivote.add_child(modelo)
	return pivote


func _es_jugador(body: Node) -> bool:
	return body is CharacterBody3D and body.has_method("habilitar_salto")


func _colocar_en_suelo() -> void:
	var origen := global_position + Vector3.UP * 30.0
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + Vector3.DOWN * 80.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(consulta)
	if hit and not _es_jugador(hit.collider):
		global_position.y = hit.position.y
