class_name InteractRay
extends RayCast3D
## For first-person / third-person games: make this a child of your Camera3D.
## Press `interact_action` (or left click while the mouse is captured)
## while looking at an Interactable3D to open its popup.

## Emitted when the player starts/stops looking at something (use it to show "Press E").
signal target_changed(target: Interactable3D)

@export var interact_action := "interact"
@export var reach := 2.5

var target: Interactable3D = null


func _ready() -> void:
	collide_with_areas = true
	target_position = Vector3(0, 0, -reach)


func _physics_process(_delta: float) -> void:
	var hit := get_collider() as Interactable3D
	if hit != target:
		target = hit
		target_changed.emit(target)


func _unhandled_input(event: InputEvent) -> void:
	if target == null or PopupManager.is_open():
		return
	var pressed_action: bool = InputMap.has_action(interact_action) and event.is_action_pressed(interact_action)
	var captured_click: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
		and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if pressed_action or captured_click:
		target.interact()
		get_viewport().set_input_as_handled()
