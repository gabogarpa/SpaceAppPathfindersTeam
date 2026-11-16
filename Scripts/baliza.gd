extends "res://Scripts/zona_interaccion.gd"
## Baliza de telemetría. Al activarla con [E] su luz pasa de rojo a verde.

const ROJO := Color(1.0, 0.12, 0.08)
const VERDE := Color(0.2, 1.0, 0.35)

## Altura de la luz sobre el origen de la baliza. < 0 = arriba del modelo.
@export var altura_luz: float = -1.0

var _material := StandardMaterial3D.new()
var _luz := OmniLight3D.new()


func _init() -> void:
	herramienta_requerida = ""
	mensaje = "Telemetry beacon - offline"
	accion_texto = "Activate telemetry beacon"
	ajustar_al_suelo = false
	es_objetivo = false


func _al_iniciar() -> void:
	var y := altura_luz
	if y < 0.0:
		var caja := Inventario.calcular_aabb(self)
		y = caja.end.y + 0.25 if caja.size != Vector3.ONE else 2.0
	_material.albedo_color = ROJO
	_material.emission_enabled = true
	_material.emission = ROJO
	_material.emission_energy_multiplier = 2.5
	var esfera := SphereMesh.new()
	esfera.radius = 0.25
	esfera.height = 0.5
	esfera.material = _material
	var foco := MeshInstance3D.new()
	foco.mesh = esfera
	foco.position = Vector3.UP * y
	add_child(foco)
	_luz.light_color = ROJO
	_luz.light_energy = 1.5
	_luz.omni_range = 5.0
	_luz.position = Vector3.UP * y
	add_child(_luz)


func encendida() -> bool:
	return esta_completada()


func _usar() -> void:
	completar()
	var t := create_tween().set_parallel(true)
	t.tween_property(_material, "albedo_color", VERDE, 0.4)
	t.tween_property(_material, "emission", VERDE, 0.4)
	t.tween_property(_luz, "light_color", VERDE, 0.4)
	await t.finished
