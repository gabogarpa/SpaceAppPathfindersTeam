class_name DropSlot
extends Panel
## A place where a DraggableItem can be dropped. Holds one item.
## The parent PuzzlePopup solves itself when every slot is correct.

signal item_placed(slot: DropSlot, item: DraggableItem)
signal item_removed(slot: DropSlot, item: DraggableItem)
signal changed(slot: DropSlot)

## The item_id that is correct here. Empty = any item counts as correct.
@export var accepted_item_id := ""
## true: wrong items bounce back. false: any item can be placed, but only the right one is "correct".
@export var only_accept_correct := false
## Once the correct item is placed it can't be dragged out anymore.
@export var lock_when_correct := false

var item: DraggableItem = null
var locked := false


func _ready() -> void:
	resized.connect(_center_item)
	for child in get_children():
		if child is DraggableItem and item == null:
			_hold(child)


func is_correct() -> bool:
	return item != null and (accepted_item_id == "" or item.item_id == accepted_item_id)


func accepts(new_item: DraggableItem) -> bool:
	if locked:
		return false
	if only_accept_correct and accepted_item_id != "" and new_item.item_id != accepted_item_id:
		return false
	return true


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is DraggableItem and data != item and accepts(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	place(data)


## Put an item here (also usable from code). Swaps if the slot is full.
func place(new_item: DraggableItem) -> void:
	var from_slot := new_item.current_slot
	var old_item := item
	if from_slot:
		from_slot._release()
	if old_item:
		_release()
		if from_slot and from_slot.accepts(old_item):
			from_slot._hold(old_item)
		else:
			old_item.return_home()
	_hold(new_item)


## Send the current item back home.
func clear() -> void:
	if item:
		item.return_home()


func _hold(new_item: DraggableItem) -> void:
	item = new_item
	new_item.current_slot = self
	if new_item.get_parent() != self:
		new_item.reparent(self, false)
	_center_item()
	if lock_when_correct and is_correct():
		locked = true
	item_placed.emit(self, new_item)
	changed.emit(self)


func _release() -> void:
	var old_item := item
	item = null
	old_item.current_slot = null
	item_removed.emit(self, old_item)
	changed.emit(self)


func _center_item() -> void:
	if item:
		item.position = (size - item.size) / 2.0
