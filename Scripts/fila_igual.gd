@tool
class_name FilaIgual
extends VBoxContainer
## Ordena a sus hijos de izquierda a derecha, todos con el mismo ancho y el alto completo.

@export var separacion: int = 8:
	set(valor):
		separacion = valor
		queue_sort()
		update_minimum_size()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_ordenar()


func _hijos() -> Array[Control]:
	var lista: Array[Control] = []
	for c in get_children():
		if c is Control and c.visible and not c.top_level:
			lista.append(c)
	return lista


func _ordenar() -> void:
	var hijos := _hijos()
	var n := hijos.size()
	if n == 0:
		return
	var ancho := (size.x - separacion * (n - 1)) / n
	for i in n:
		fit_child_in_rect(hijos[i], Rect2(i * (ancho + separacion), 0, ancho, size.y))


func _get_minimum_size() -> Vector2:
	var hijos := _hijos()
	var minimo := Vector2.ZERO
	for c in hijos:
		var m := c.get_combined_minimum_size()
		minimo.x = maxf(minimo.x, m.x)
		minimo.y = maxf(minimo.y, m.y)
	var n := hijos.size()
	if n == 0:
		return Vector2.ZERO
	return Vector2(minimo.x * n + separacion * (n - 1), minimo.y)
