extends Area3D
# Montículo de polvo lunar. Al acercarte aparece "Usa la escoba [F]".
# Con la herramienta equipada y pulsando F, el polvo se barre, queda un cráter
# y aparece la recompensa (por defecto el brazo robótico) flotando.

@export var objeto_requerido: String = "escoba"
@export var mensaje: String = "Usa la escoba  [F]"
@export var mensaje_listo: String = "Pulsa [F] para usarla"
@export var escena_recompensa: PackedScene
@export var radio_crater: float = 1.6
@export var altura_recompensa: float = 1.2
## Si está activo, al iniciar el montículo se pega al terreno (rayo hacia abajo),
## así no hace falta calcular la altura a mano al moverlo en el editor.
@export var ajustar_al_suelo: bool = true

@onready var _polvo: MeshInstance3D = $Polvo

var robot_cerca: Node3D = null
var usada := false
var _inv: Node  # el autoload Inventario

func _ready() -> void:
	_inv = get_node("/root/Inventario")
	print("ZonaPolvo lista en ", global_position)  # confirma que el script cargó
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_inv.equipado_cambiado.connect(func(_id): _actualizar_prompt())
	if ajustar_al_suelo:
		_pegar_al_suelo()

func _pegar_al_suelo() -> void:
	# Esperamos a que la física registre el terreno (colisiones trimesh)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var espacio := get_world_3d().direct_space_state
	var desde := global_position + Vector3(0, 60, 0)
	var hasta := global_position - Vector3(0, 60, 0)
	var q := PhysicsRayQueryParameters3D.create(desde, hasta)
	var r := espacio.intersect_ray(q)
	if r.is_empty():
		push_warning("ZonaPolvo: no se encontró terreno debajo; se deja la altura del editor.")
		return
	global_position.y = r["position"].y

func _on_body_entered(body: Node3D) -> void:
	if usada or not body.is_in_group("robot"):
		return
	robot_cerca = body
	_actualizar_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == robot_cerca:
		robot_cerca = null
		_inv.ocultar_prompt()

func _actualizar_prompt() -> void:
	if usada or robot_cerca == null:
		return
	if _inv.equipado == objeto_requerido:
		_inv.mostrar_prompt(mensaje_listo)
	else:
		_inv.mostrar_prompt(mensaje)

func _unhandled_input(event: InputEvent) -> void:
	if usada or robot_cerca == null:
		return
	if event.is_action_pressed("usar_objeto"):
		if _inv.equipado == objeto_requerido:
			_barrer()
		else:
			_inv.mostrar_aviso("Abre el almacén [I] y equipa la herramienta")

func _barrer() -> void:
	usada = true
	robot_cerca = null
	_inv.ocultar_prompt()
	set_deferred("monitoring", false)
	_polvareda()
	var t := create_tween()
	t.tween_property(_polvo, "scale", Vector3(0.1, 0.02, 0.1), 1.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_terminar_barrido)

func _terminar_barrido() -> void:
	_polvo.queue_free()
	_crear_crater()
	_soltar_recompensa()
	_inv.mostrar_aviso("¡Quitaste el polvo!")

func _polvareda() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.68, 0.64)
	var esfera := SphereMesh.new()
	esfera.radius = 0.08
	esfera.height = 0.16
	esfera.material = mat

	var p := CPUParticles3D.new()
	p.mesh = esfera
	p.one_shot = true
	p.amount = 40
	p.lifetime = 1.4
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -1.6, 0)  # gravedad lunar
	p.position = Vector3(0, 0.3, 0)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(2.5).timeout.connect(p.queue_free)

func _crear_crater() -> void:
	# Disco oscuro en el suelo
	var mat_fondo := StandardMaterial3D.new()
	mat_fondo.albedo_color = Color(0.2, 0.19, 0.18)
	mat_fondo.roughness = 1.0
	var cil := CylinderMesh.new()
	cil.top_radius = radio_crater
	cil.bottom_radius = radio_crater
	cil.height = 0.02
	cil.radial_segments = 32
	cil.material = mat_fondo
	var disco := MeshInstance3D.new()
	disco.mesh = cil
	disco.position = Vector3(0, 0.05, 0)
	add_child(disco)

	# Borde levantado alrededor del cráter
	var mat_borde := StandardMaterial3D.new()
	mat_borde.albedo_color = Color(0.5, 0.48, 0.45)
	mat_borde.roughness = 1.0
	var toro := TorusMesh.new()
	toro.inner_radius = radio_crater - 0.1
	toro.outer_radius = radio_crater + 0.25
	toro.material = mat_borde
	var borde := MeshInstance3D.new()
	borde.mesh = toro
	borde.scale = Vector3(1, 0.5, 1)
	borde.position = Vector3(0, 0.08, 0)
	add_child(borde)

func _soltar_recompensa() -> void:
	if escena_recompensa == null:
		return
	var padre := get_parent() as Node3D
	if padre == null:
		return
	var obj := escena_recompensa.instantiate() as Node3D
	# La posición se fija antes de añadirlo para que la flotación parta de la altura correcta
	obj.position = padre.to_local(global_position + Vector3(0, altura_recompensa, 0))
	padre.add_child(obj)
	obj.scale = Vector3.ONE * 0.01
	create_tween().tween_property(obj, "scale", Vector3.ONE, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
