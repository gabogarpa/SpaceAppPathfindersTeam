extends Node3D
## Sistema Rocker-Bogie cubierto de chatarra. El Area3D (zona_puzzle.gd) pide el iman,
## abre el puzzle de la chatarra y al resolverlo suelta las ruedas para recogerlas.

@onready var area_interactiva = $Area3D
@onready var chatarra_3d: Node3D = $chatarra_marron
@onready var ruedas_3d: Node3D = get_child(0)


func _ready() -> void:
	area_interactiva.ocultar = [chatarra_3d]
	area_interactiva.completada.connect(_al_liberar_rocker_boogie)


func _al_liberar_rocker_boogie() -> void:
	if is_in_group("objeto_clave"):
		remove_from_group("objeto_clave")
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(ruedas_3d):
		ruedas_3d.hide()
