extends Node3D

@onready var area_interactiva: Interactable3D = $Area3D # Ajusta si tu Area3D se llama distinto
@onready var chatarra_3d: Node3D = $chatarra_marron

func _ready() -> void:
	# Escuchamos la señal 'solved' que emite Interactable3D al completar el popup
	area_interactiva.solved.connect(_al_liberar_rocker_boogie)

func _al_liberar_rocker_boogie() -> void:
	print("¡RockerBoogie liberado de la chatarra!")
	
	# 1. Si estaba en el grupo de la sonda localizadora, lo sacamos para que deje de pitar
	if is_in_group("objeto_clave"):
		remove_from_group("objeto_clave")
		
	chatarra_3d.queue_free()
