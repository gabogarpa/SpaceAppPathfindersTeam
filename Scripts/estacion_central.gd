extends "res://Scripts/zona_interaccion.gd"
## Estación central (ALSEP). Sin energía al inicio; al instalar el cilindro
## SNAP-27 se encienden sus luces.

signal activada

@export var item_requerido := "snap27"

@onready var cilindro: Node3D = $Cilindro
@onready var luces: Node3D = $Luces

var _material_foco := StandardMaterial3D.new()


func _init() -> void:
	herramienta_requerida = ""
	mensaje = "ALSEP central station - no power"
	guia = "estacion"
	accion_texto = "Install the SNAP-27 generator"
	es_objetivo = false


func _al_iniciar() -> void:
	cilindro.hide()
	_material_foco.albedo_color = Color(0.25, 0.25, 0.22)
	_material_foco.emission_enabled = true
	_material_foco.emission = Color(1.0, 0.85, 0.45)
	_material_foco.emission_energy_multiplier = 0.0
	for n in find_children("Foco*", "MeshInstance3D", true, false):
		n.material_override = _material_foco
	for l in luces.get_children():
		if l is Light3D:
			l.light_energy = 0.0
	Inventario.item_agregado.connect(_on_item_agregado)


func _on_item_agregado(id: String) -> void:
	if id == item_requerido and not esta_completada():
		add_to_group("objeto_clave")


func _requisito_faltante() -> String:
	if Inventario.tiene(item_requerido):
		return ""
	return "You need the %s to power it" % Inventario.nombre_de(item_requerido)


func _usar() -> void:
	completar()
	Inventario.quitar(item_requerido)
	var destino := cilindro.position
	cilindro.position = destino + Vector3.UP * 2.0
	cilindro.show()
	var t := create_tween()
	t.tween_property(cilindro, "position", destino, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await t.finished

	var domo := get_node_or_null("Domo") as MeshInstance3D
	if domo and domo.mesh and domo.mesh.surface_get_material(0) is StandardMaterial3D:
		var cristal: StandardMaterial3D = domo.mesh.surface_get_material(0)
		cristal.emission_enabled = true
		cristal.emission = Color(0.4, 0.8, 1.0)
		cristal.emission_energy_multiplier = 0.0
		create_tween().tween_property(cristal, "emission_energy_multiplier", 0.8, 1.0)
	var mt := create_tween()
	mt.tween_property(_material_foco, "albedo_color", Color(1, 0.95, 0.8), 0.4)
	mt.parallel().tween_property(_material_foco, "emission_energy_multiplier", 3.0, 0.4)
	for l in luces.get_children():
		if l is Light3D:
			var lt := create_tween()
			lt.tween_property(l, "light_energy", l.get_meta("energia", 2.0), 0.3)
			await get_tree().create_timer(0.25).timeout
	Inventario.mostrar_aviso("Central station online!\nThe SNAP-27 is supplying power again", 3.5)
	activada.emit()
	Inventario.completar_objetivo("estacion")
