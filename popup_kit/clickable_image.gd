class_name ClickableImage
extends TextureButton
## An image you can click. Grows a bit on hover.
## If `states` has textures, each click cycles to the next one
## (great for dials, switches, symbol locks, rotating pieces...).

signal clicked(image: ClickableImage)
signal state_changed(image: ClickableImage, index: int)

## Any name you want, so your puzzle script knows which image was clicked.
@export var id := ""
@export var states: Array[Texture2D] = []
@export var state := 0: set = set_state
@export var hover_scale := 1.08


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_tween_scale.bind(hover_scale))
	mouse_exited.connect(_tween_scale.bind(1.0))
	resized.connect(func(): pivot_offset = size / 2.0)
	pivot_offset = size / 2.0
	_apply_state()


func set_state(value: int) -> void:
	if not states.is_empty():
		value = wrapi(value, 0, states.size())
	var changed := value != state
	state = value
	if is_node_ready():
		_apply_state()
		if changed:
			state_changed.emit(self, state)


func _on_pressed() -> void:
	if not states.is_empty():
		set_state(state + 1)
	clicked.emit(self)


func _apply_state() -> void:
	if state >= 0 and state < states.size():
		texture_normal = states[state]


func _tween_scale(target: float) -> void:
	if disabled:
		return
	create_tween().tween_property(self, "scale", Vector2.ONE * target, 0.1)
