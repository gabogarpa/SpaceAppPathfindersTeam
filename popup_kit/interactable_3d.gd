class_name Interactable3D
extends Area3D
## Put this on an Area3D (with a CollisionShape3D child) on any 3D object.
## Opens `popup_scene` when clicked with a visible mouse, or when interact() is
## called (e.g. by InteractRay for first-person games).

signal opened(popup: PuzzlePopup)
## Connect this to whatever should happen in the 3D world (open a door, etc.).
signal solved

@export var popup_scene: PackedScene
## Extra data for the popup, readable there as `context`.
@export var context: Dictionary = {}
@export var open_on_mouse_click := true
## Can't be opened again once its puzzle is solved.
@export var disable_when_solved := false

var is_solved := false


func _ready() -> void:
	input_ray_pickable = true
	input_event.connect(_on_input_event)


func interact() -> void:
	if popup_scene == null or PopupManager.is_open():
		return
	if disable_when_solved and is_solved:
		return
	var ctx := context.duplicate()
	ctx["source"] = self
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
