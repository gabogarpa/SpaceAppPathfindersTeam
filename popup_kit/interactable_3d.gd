class_name Interactable3D
extends Area3D

signal opened(popup: PuzzlePopup)
signal solved

@export var popup_scene: PackedScene
@export var context: Dictionary = {}
@export var open_on_mouse_click := true
@export var open_on_proximity := true # NUEVO: Se abre al acercarse
@export var disable_when_solved := true # Cambiado a true para que no se reabra al resolverlo

var is_solved := false


func _ready() -> void:
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	body_entered.connect(_on_body_entered) # NUEVO: Detecta cuando MoonBot entra al área


func _on_body_entered(body: Node3D) -> void:
	# Si el nodo que entró es el jugador (CharacterBody3D), abrimos el puzzle
	if open_on_proximity and body is CharacterBody3D:
		interact()


func interact() -> void:
	if popup_scene == null or PopupManager.is_open():
		return
	if disable_when_solved and is_solved:
		return
	var ctx := context.duplicate()
	ctx["source"] = self
	
	# CAMBIA ESTA LÍNEA (le indicamos explícitamente que es un PuzzlePopup):
	var popup: PuzzlePopup = PopupManager.open(popup_scene, ctx)
	
	popup.solved.connect(_on_popup_solved)
	opened.emit(popup)


func _on_popup_solved() -> void:
	if not is_solved:
		is_solved = true
		solved.emit()


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	if not open_on_mouse_click or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact()
