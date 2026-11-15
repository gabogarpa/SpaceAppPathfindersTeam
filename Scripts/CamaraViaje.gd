extends Camera3D

# Al usar @export, estas variables aparecerán en el Inspector a la derecha
@export var temblando: bool = true
@export var intensidad: float = 0.05

func _ready() -> void:
	# Sobreescribe la cámara de MoonBot
	make_current()

func _process(_delta: float) -> void:
	if temblando:
		# Genera una vibración constante en cada fotograma
		h_offset = randf_range(-intensidad, intensidad)
		v_offset = randf_range(-intensidad, intensidad)
	else:
		# Centra la lente si el viaje en cohete se detiene
		h_offset = 0.0
		v_offset = 0.0
