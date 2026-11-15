class_name PuzzlePopup
extends Control
## Base for every popup / puzzle screen. Use it as the root of a popup scene,
## or extend it ("extends PuzzlePopup") to add custom puzzle logic.
##
## Override these in your own scripts:
##   _on_opened()          - popup just opened, `context` is filled
##   _on_solved()          - puzzle just got solved
##   _on_already_solved()  - popup opened but the puzzle was solved before

signal solved
signal closed

## Unique id so the game remembers this puzzle is solved. Leave empty to not remember.
@export var puzzle_id := ""
## Optional button that closes the popup.
@export var close_button: BaseButton
@export var close_on_escape := true
## Solve automatically when every DropSlot in this popup holds its correct item.
@export var check_slots_automatically := true
## Seconds to wait after solving before closing. Use -1 to keep the popup open.
@export var close_delay_after_solve := 0.8

## Data passed by whoever opened the popup (e.g. {"source": the Interactable3D}).
var context: Dictionary = {}
var is_solved := false

var _closing := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if close_button:
		close_button.pressed.connect(close)
	for slot in get_slots():
		slot.changed.connect(_on_slot_changed)


func _open(ctx: Dictionary) -> void:
	context = ctx
	if puzzle_id != "" and PopupManager.is_solved(puzzle_id):
		is_solved = true
	_on_opened()
	if is_solved:
		_on_already_solved()


func solve() -> void:
	if is_solved:
		return
	is_solved = true
	if puzzle_id != "":
		PopupManager.mark_solved(puzzle_id)
	_on_solved()
	solved.emit()
	if close_delay_after_solve >= 0.0:
		await get_tree().create_timer(close_delay_after_solve).timeout
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	closed.emit()
	PopupManager.close(self)


## Every DropSlot inside this popup.
func get_slots() -> Array[DropSlot]:
	var result: Array[DropSlot] = []
	_collect_slots(self, result)
	return result


func all_slots_correct() -> bool:
	var slots := get_slots()
	if slots.is_empty():
		return false
	for slot in slots:
		if not slot.is_correct():
			return false
	return true


func _on_slot_changed(_slot: DropSlot) -> void:
	if check_slots_automatically and not is_solved and all_slots_correct():
		solve()


func _collect_slots(node: Node, result: Array[DropSlot]) -> void:
	for child in node.get_children():
		if child is DropSlot:
			result.append(child)
		_collect_slots(child, result)


func _on_opened() -> void:
	pass


func _on_solved() -> void:
	pass


func _on_already_solved() -> void:
	pass
