extends Label
# Muestra en pantalla los objetos guardados en el Inventario.

func _ready() -> void:
	position = Vector2(16, 16)
	Inventario.objeto_agregado.connect(func(_id): _actualizar())
	_actualizar()

func _actualizar() -> void:
	if Inventario.objetos.is_empty():
		text = "Almacén: (vacío)"
	else:
		text = "Almacén: " + ", ".join(PackedStringArray(Inventario.objetos))
