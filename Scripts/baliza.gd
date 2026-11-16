extends "res://Scripts/zona_interaccion.gd"
## Baliza de telemetria: con [E] cambia su luz de rojo a verde.

signal activada

var guia_habilitada := false
var _luz: OmniLight3D
var _foco: MeshInstance3D
var _material := StandardMaterial3D.new()


func _init() -> void:
	ajustar_al_suelo = false
	es_objetivo = false
	mensaje = "Telemetry beacon - offline"
	accion_texto = "Activate beacon"


func _al_iniciar() -> void:
	add_to_group("guia")
	_material.albedo_color = Color(1, 0.15, 0.1)
	_material.emission_enabled = true
	_material.emission = Color(1, 0.15, 0.1)
	_material.emission_energy_multiplier = 2.5
	_foco = MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.25
	esfera.height = 0.5
	_foco.mesh = esfera
	_foco.material_override = _material
	_foco.position = Vector3(0, 4.0, 0)
	add_child(_foco)
	_luz = OmniLight3D.new()
	_luz.light_color = Color(1, 0.15, 0.1)
	_luz.light_energy = 2.0
	_luz.omni_range = 6.0
	_luz.position = Vector3(0, 4.0, 0)
	add_child(_luz)


func es_guia_activa() -> bool:
	return guia_habilitada and not esta_completada()


func _usar() -> void:
	completar()
	var verde := Color(0.2, 1, 0.3)
	var t := create_tween().set_parallel(true)
	t.tween_property(_material, "albedo_color", verde, 0.4)
	t.tween_property(_material, "emission", verde, 0.4)
	t.tween_property(_luz, "light_color", verde, 0.4)
	await t.finished
	activada.emit()
