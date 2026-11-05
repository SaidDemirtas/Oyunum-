class_name InventorySlot
extends Resource

@export var item_data: Resource # ItemData veya ConsumableData olabilir
@export var quantity: int = 1

func can_stack_with(other_item: Resource) -> bool:
	if item_data == null or other_item == null:
		return false
	if item_data == other_item and item_data is ConsumableData:
		var consumable = item_data as ConsumableData
		return quantity < consumable.max_stack_size
	return false
