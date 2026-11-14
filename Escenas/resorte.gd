extends Area3D

@export var velocidad_rotacion: float = 2.5
@export var altura_flotacion: float = 0.15

var tiempo: float = 0.0
var posicion_inicial_y: float = 0.0

func _ready() -> void:
	posicion_inicial_y = position.y

func _process(delta: float) -> void:
	# Efecto visual de giro y flotación
	rotate_y(velocidad_rotacion * delta)
	tiempo += delta * 3.0
	position.y = posicion_inicial_y + sin(tiempo) * altura_flotacion

func _on_body_entered(body: Node3D) -> void:
	# Verifica si quien lo tocó tiene la función habilitar_salto (MoonBot)
	if body.has_method("habilitar_salto"):
		body.habilitar_salto()
		queue_free() # Desaparece el resorte del mapa
