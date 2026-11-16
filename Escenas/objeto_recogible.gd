extends Area3D
# Objeto que el robot recoge con la tecla E y guarda en el Inventario.

@export var id_objeto: String = "escoba"
@export var velocidad_rotacion: float = 1.5
@export var altura_flotacion: float = 0.1

var robot_cerca: Node3D = null
var tiempo: float = 0.0
var y_inicial: float = 0.0

func _ready() -> void:
	y_inicial = position.y
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Mismo efecto de giro y flotación que el resorte
	rotate_y(velocidad_rotacion * delta)
	tiempo += delta * 3.0
	position.y = y_inicial + sin(tiempo) * altura_flotacion

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("robot"):
		robot_cerca = body

func _on_body_exited(body: Node3D) -> void:
	if body == robot_cerca:
		robot_cerca = null

func _unhandled_input(event: InputEvent) -> void:
	if robot_cerca and event.is_action_pressed("interactuar"):
		Inventario.agregar(id_objeto)
		queue_free()
