extends Area3D
## Objeto flotante que gira y se agrega al Inventario cuando el MoonBot lo toca.
## Sirve para la escoba, el brazo robótico o cualquier pieza nueva.

signal recogido(id: String)

@export var item_id := ""
@export var velocidad_rotacion: float = 2.5
@export var altura_flotacion: float = 0.15
## Segundos antes de poder recogerlo (para que se vea aparecer).
@export var retraso_recogida: float = 0.0
## Al iniciar, lo coloca a `altura_sobre_suelo` metros encima del terreno.
@export var ajustar_al_suelo := false
@export var altura_sobre_suelo: float = 0.5
## Muestra la ficha de la pieza al recogerla (false = se muestra en otro momento, p. ej. al instalarla).
@export var mostrar_ficha := true
## Tapado (bajo polvo, rocas, chatarra...): no gira ni se puede recoger hasta llamar a liberar().
@export var bloqueado := false
## Metros que sube al liberarse.
@export var altura_liberar: float = 1.0

var tiempo: float = 0.0
var posicion_inicial_y: float = 0.0
var _activo := false


func _ready() -> void:
	posicion_inicial_y = position.y
	body_entered.connect(_on_body_entered)
	if ajustar_al_suelo:
		await get_tree().physics_frame
		_colocar_en_suelo()
	if bloqueado:
		return
	if retraso_recogida > 0.0:
		await get_tree().create_timer(retraso_recogida).timeout
	_activar()


func _activar() -> void:
	_activo = true
	for body in get_overlapping_bodies():
		_on_body_entered(body)


## Destapa la pieza: sube un poco, empieza a girar y ya se puede recoger.
func liberar() -> void:
	if not bloqueado:
		return
	var t := create_tween()
	t.tween_property(self, "position:y", position.y + altura_liberar, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	posicion_inicial_y = position.y
	tiempo = 0.0
	bloqueado = false
	await get_tree().create_timer(0.4).timeout
	_activar()


func _process(delta: float) -> void:
	if bloqueado:
		return
	rotate_y(velocidad_rotacion * delta)
	tiempo += delta * 3.0
	position.y = posicion_inicial_y + sin(tiempo) * altura_flotacion


func _on_body_entered(body: Node3D) -> void:
	if not _activo or not _es_jugador(body):
		return
	_activo = false
	Inventario.agregar(item_id)
	var robot := Inventario.robot_de(item_id)
	var pista := ""
	if not Inventario.es_herramienta(item_id) and Inventario.uso_de(item_id) != "":
		pista = "\n" + Inventario.uso_de(item_id)
	Inventario.mostrar_aviso("You got: %s%s%s\n[%s] Open inventory" % [
		Inventario.nombre_de(item_id), "\nRobot: %s" % robot if robot != "" else "", pista,
		Inventario.tecla_de(Inventario.ACCION_INVENTARIO)], 4.0)
	recogido.emit(item_id)
	queue_free()
	if mostrar_ficha:
		Inventario.mostrar_ficha(item_id)
	if item_id in Inventario.objetivos:
		Inventario.completar_objetivo(item_id)


func _es_jugador(body: Node) -> bool:
	return body is CharacterBody3D and body.has_method("habilitar_salto")


func _colocar_en_suelo() -> void:
	var origen := global_position + Vector3.UP * 30.0
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + Vector3.DOWN * 80.0)
	consulta.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(consulta)
	if hit and not _es_jugador(hit.collider):
		global_position.y = hit.position.y + altura_sobre_suelo
		posicion_inicial_y = position.y
