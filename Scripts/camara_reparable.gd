extends "res://Scripts/zona_interaccion.gd"
## Cámara de televisión del Apolo 12. Con el brazo robótico se levanta y se abre
## una ventana con el esquema de sus partes; ahí se arrastra la celda de batería
## desde el inventario del robot a su compartimiento.

const VENTANA := preload("res://Escenas/UI/ventana_camara.tscn")

@export var altura_levantar: float = 1.2

@onready var modelo: Node3D = get_child(0)

var _levantada := false
var _pos_modelo := Vector3.ZERO


func _init() -> void:
	herramienta_requerida = "brazo_robotico"
	mensaje = "Television camera - no power"
	guia = "camara"
	ajustar_al_suelo = false


func _al_iniciar() -> void:
	_pos_modelo = modelo.position


func _herramienta() -> String:
	return "" if _levantada else herramienta_requerida


func _usar() -> void:
	if not _levantada:
		accion_texto = "Open camera schematic"
		var brazo := animar_herramienta(herramienta_requerida, 1.2)
		await get_tree().create_timer(0.5).timeout
		var t := create_tween().set_parallel(true)
		t.tween_property(modelo, "position", _pos_modelo + Vector3.UP * altura_levantar, 0.6) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(modelo, "rotation_degrees:x", -12.0, 0.6)
		await brazo
		_levantada = true
	var popup = PopupManager.open(VENTANA, {"source": self})
	popup.solved.connect(_on_reparada)
	await popup.closed


func _on_reparada() -> void:
	completar()
	Inventario.quitar("bateria")
	await PopupManager.popup_closed
	var t := create_tween().set_parallel(true)
	t.tween_property(modelo, "position", _pos_modelo, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(modelo, "rotation_degrees:x", 0.0, 0.4)
	Inventario.mostrar_aviso("Camera powered!", 2.5)
	await t.finished
	Inventario.mostrar_ficha("camara_tv")
	Inventario.completar_objetivo("camara")
