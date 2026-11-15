extends Node
## Autoload this script as "PopupManager" (Project Settings > Globals > Autoload).
## Opens puzzle popups on top of the 3D game, pauses the game, frees the mouse,
## and remembers which puzzles are solved.

signal popup_opened(popup: PuzzlePopup)
signal popup_closed(popup: PuzzlePopup)

## Pause the 3D world (player movement, physics, etc.) while a popup is open.
@export var pause_game := true

var solved_puzzles := {}

var _stack: Array[PuzzlePopup] = []
var _layer: CanvasLayer
var _prev_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _prev_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)


func open(scene: PackedScene, context: Dictionary = {}) -> PuzzlePopup:
	var popup := scene.instantiate() as PuzzlePopup
	assert(popup != null, "The root node of a popup scene must use puzzle_popup.gd or a script that extends PuzzlePopup.")
	if _stack.is_empty():
		_prev_mouse_mode = Input.mouse_mode
		_prev_paused = get_tree().paused
	_stack.append(popup)
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.add_child(popup)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if pause_game:
		get_tree().paused = true
	popup._open(context)
	popup_opened.emit(popup)
	return popup


func close(popup: PuzzlePopup) -> void:
	if not _stack.has(popup):
		return
	_stack.erase(popup)
	popup_closed.emit(popup)
	popup.queue_free()
	if _stack.is_empty():
		get_tree().paused = _prev_paused
		Input.mouse_mode = _prev_mouse_mode


func close_top() -> void:
	if not _stack.is_empty():
		_stack.back().close()


func is_open() -> bool:
	return not _stack.is_empty()


func current() -> PuzzlePopup:
	return null if _stack.is_empty() else _stack.back()


func is_solved(puzzle_id: String) -> bool:
	return solved_puzzles.get(puzzle_id, false)


func mark_solved(puzzle_id: String) -> void:
	solved_puzzles[puzzle_id] = true


func _unhandled_input(event: InputEvent) -> void:
	if _stack.is_empty():
		return
	if event.is_action_pressed("ui_cancel") and _stack.back().close_on_escape:
		_stack.back().close()
		get_viewport().set_input_as_handled()
