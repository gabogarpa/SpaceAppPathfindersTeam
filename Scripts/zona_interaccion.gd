extends Area3D
## Base para zonas que el MoonBot activa con la tecla de usar (E).
## Muestra avisos según la herramienta requerida y llama a _usar() cuando se cumple.
## Las zonas concretas (polvo, chatarra, rocas, cámara, estación) extienden este script.

signal completada

## Id de la herramienta que debe estar equipada. Vacío = no requiere herramienta.
@export var herramienta_requerida := ""
@export var mensaje := ""
## Texto de la acción, p. ej. "Usar escoba". Vacío = "Usar <herramienta>".
@export var accion_texto := ""
## Al iniciar, baja/sube la zona hasta tocar el terreno.
@export var ajustar_al_suelo := true
## Agrega la zona al grupo "objeto_clave".
@export var es_objetivo := true
## Paso de la mision al que apunta el radar (grupo "guia_<paso>"): polvo, bateria, camara, snap, estacion.
@export var guia := ""

var _jugador: Node3D = null
var _completada := false
var _ocupada := false


func _ready() -> void:
	if es_objetivo:
		add_to_group("objeto_clave")
	if guia != "":
		add_to_group("guia_" + guia)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Inventario.herramienta_equipada.connect(_actualizar_aviso.unbind(1))
	Inventario.item_agregado.connect(_actualizar_aviso.unbind(1))
	_al_iniciar()
	if ajustar_al_suelo:
		await get_tree().physics_frame
		_colocar_en_suelo()


# ------------------------------------------------ Para sobrescribir

func _al_iniciar() -> void:
	pass


## Acción principal (puede usar await). Llama a completar() cuando termine del todo.
func _usar() -> void:
	pass


## Herramienta que se pide en este momento (p. ej. la cámara ya levantada no pide nada).
func _herramienta() -> String:
	return herramienta_requerida


## Devuelve un texto si falta algo (aparte de la herramienta), o "" si se puede usar.
func _requisito_faltante() -> String:
	return ""


# ------------------------------------------------ Lógica común

func completar() -> void:
	if _completada:
		return
	_completada = true
	remove_from_group("objeto_clave")
	completada.emit()


func esta_completada() -> bool:
	return _completada


func _on_body_entered(body: Node3D) -> void:
	if _completada or not _es_jugador(body):
		return
	_jugador = body
	_actualizar_aviso()


func _on_body_exited(body: Node3D) -> void:
	if body != _jugador:
		return
	_jugador = null
	if not _completada and not _ocupada:
		Inventario.ocultar_aviso()


func _actualizar_aviso() -> void:
	if _jugador == null or _completada or _ocupada:
		return
	var tecla_usar := Inventario.tecla_de(Inventario.ACCION_USAR)
	var herramienta := _herramienta()
	var nombre: String = Inventario.nombre_de(herramienta).to_lower()
	var detalle: String
	var falta := _requisito_faltante()
	if falta != "":
		detalle = falta
	elif herramienta == "" or Inventario.equipada == herramienta:
		var accion := accion_texto if accion_texto != "" else "Use %s" % nombre
		detalle = "[%s] %s" % [tecla_usar, accion]
	elif Inventario.tiene(herramienta):
		detalle = "[%s] Open inventory and equip the %s" % [
			Inventario.tecla_de(Inventario.ACCION_INVENTARIO), nombre]
	else:
		detalle = "You need to find: %s" % nombre
	Inventario.mostrar_aviso(detalle if mensaje == "" else "%s\n%s" % [mensaje, detalle])


func _unhandled_input(event: InputEvent) -> void:
	if _completada or _ocupada or _jugador == null or Inventario.bloqueado:
		return
	if not event.is_action_pressed(Inventario.ACCION_USAR):
		return
	get_viewport().set_input_as_handled()
	var herramienta := _herramienta()
	if _requisito_faltante() != "" or (herramienta != "" and Inventario.equipada != herramienta):
		_actualizar_aviso()
		return
	_ocupada = true
	Inventario.ocultar_aviso()
	await _usar()
	_ocupada = false
	_actualizar_aviso()


## Anima la herramienta junto a la zona. Devuelve una señal para hacer `await`.
func animar_herramienta(id: String, duracion: float) -> Signal:
	var ruta: String = Inventario.modelo_de(id)
	if ruta == "" or not ResourceLoader.exists(ruta):
		return get_tree().create_timer(duracion).timeout
	var pivote := Node3D.new()
	add_child(pivote)
	var lado := Vector3.BACK
	if _jugador:
		var d := _jugador.global_position - global_position
		d.y = 0.0
		if d.length() > 0.1:
			lado = d.normalized()
	var modelo: Node3D = load(ruta).instantiate()
	pivote.add_child(modelo)
	var t := create_tween()
	if id == "brazo_robotico":
		# El brazo sale del lado del robot, apunta al centro y hace un barrido.
		pivote.global_position = global_position + lado * 2.4 + Vector3.UP * 1.4
		pivote.look_at(global_position + Vector3.UP * 0.4, Vector3.UP)
		modelo.scale = Vector3.ONE * 0.5
		modelo.rotation_degrees.y = 90
		pivote.rotate_object_local(Vector3.RIGHT, deg_to_rad(-20))
		var y0 := pivote.rotation.y
		var paso := duracion / 4.0
		t.tween_property(pivote, "rotation:y", y0 + deg_to_rad(35), paso)
		t.tween_property(pivote, "rotation:y", y0 - deg_to_rad(35), paso * 2.0)
		t.tween_property(pivote, "rotation:y", y0, paso)
	else:
		pivote.global_position = global_position + lado * 0.9 + Vector3.UP * 0.2
		pivote.look_at(global_position + Vector3.UP * 0.2, Vector3.UP)
		modelo.scale = Vector3.ONE * 0.6
		modelo.rotation_degrees.x = -35
		var paso := duracion / 8.0
		for i in 4:
			t.tween_property(pivote, "rotation:z", deg_to_rad(35), paso)
			t.tween_property(pivote, "rotation:z", deg_to_rad(-35), paso)
	t.finished.connect(pivote.queue_free)
	return t.finished


## Instancia un objeto recogible flotando sobre la zona.
func soltar_premio(escena: PackedScene, altura: float) -> Node3D:
	if escena == null:
		return null
	var premio: Node3D = escena.instantiate()
	premio.position = Vector3(0, altura, 0)
	if "retraso_recogida" in premio:
		premio.retraso_recogida = 1.0
	if "ajustar_al_suelo" in premio:
		premio.ajustar_al_suelo = false
	premio.scale = Vector3.ONE * 0.01
	add_child(premio)
	create_tween().tween_property(premio, "scale", Vector3.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return premio


func _es_jugador(body: Node) -> bool:
	return body is CharacterBody3D and body.has_method("habilitar_salto")


func _colocar_en_suelo() -> void:
	var origen := global_position + Vector3.UP * 30.0
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + Vector3.DOWN * 80.0)
	var excluir: Array[RID] = []
	for n in find_children("*", "CollisionObject3D", true, false):
		excluir.append(n.get_rid())
	consulta.exclude = excluir
	var hit := get_world_3d().direct_space_state.intersect_ray(consulta)
	if hit and not _es_jugador(hit.collider):
		global_position.y = hit.position.y
