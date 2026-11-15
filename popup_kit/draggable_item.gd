class_name DraggableItem
extends TextureRect
## An image that can be dragged into a DropSlot.
## If dropped anywhere else it stays where it was.

signal picked_up(item: DraggableItem)

## What this item is. A DropSlot is correct when this matches its `accepted_item_id`.
@export var item_id := ""

var current_slot: DropSlot = null

var _home_parent: Node
var _home_index := 0
var _home_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_home_parent = get_parent()
	_home_index = get_index()
	_home_position = position


func _get_drag_data(at_position: Vector2) -> Variant:
	if current_slot and current_slot.locked:
		return null
	var preview := TextureRect.new()
	preview.texture = texture
	preview.expand_mode = expand_mode
	preview.stretch_mode = stretch_mode
	preview.size = size
	preview.position = -at_position
	preview.modulate = Color(1, 1, 1, 0.85)
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	modulate.a = 0.3
	picked_up.emit(self)
	return self


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0


# Dropping onto an item that sits in a slot = dropping onto that slot (swap).
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return current_slot != null and current_slot._can_drop_data(at_position, data)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	current_slot._drop_data(at_position, data)


## Send the item back to where it started (e.g. the inventory tray).
func return_home() -> void:
	if current_slot:
		current_slot._release()
	if get_parent() != _home_parent:
		reparent(_home_parent, false)
	_home_parent.move_child(self, mini(_home_index, _home_parent.get_child_count() - 1))
	if not _home_parent is Container:
		position = _home_position
