class_name InventoryManager
extends Node

signal inventory_updated

@export var max_slots: int = 16 # 16 slotluk çanta alanı
var slots: Array[InventorySlot] = []

func _ready() -> void:
	# Başlangıçta boş slotları hazırla
	if slots.is_empty():
		for i in range(max_slots):
			var new_slot = InventorySlot.new()
			new_slot.item_data = null
			new_slot.quantity = 0
			slots.append(new_slot)

# Çantaya Eşya Ekleme (Yığınlama / Stacking Destekli)
func add_item(item: Resource, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
		
	# 1. Önce var olan yığınlanabilir slotlara eklemeyi dene
	if item is ConsumableData:
		for slot in slots:
			if slot.can_stack_with(item):
				var consumable = item as ConsumableData
				var space_left = consumable.max_stack_size - slot.quantity
				var add_amount = min(amount, space_left)
				
				slot.quantity += add_amount
				amount -= add_amount
				
				if amount <= 0:
					inventory_updated.emit()
					return true

	# 2. Kalan miktarı ilk bulduğu boş slota yerleştir
	while amount > 0:
		var empty_slot = _find_first_empty_slot()
		if empty_slot == null:
			inventory_updated.emit()
			return false # Çanta tamamen dolu!
			
		empty_slot.item_data = item
		if item is ConsumableData:
			var consumable = item as ConsumableData
			var add_amount = min(amount, consumable.max_stack_size)
			empty_slot.quantity = add_amount
			amount -= add_amount
		else:
			empty_slot.quantity = 1
			amount -= 1

	inventory_updated.emit()
	return true

# Çantadan Eşya Çıkarma / Silme
func remove_item(slot_index: int, amount: int = 1) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
		
	var slot = slots[slot_index]
	if slot.item_data == null:
		return false
		
	slot.quantity -= amount
	if slot.quantity <= 0:
		slot.item_data = null
		slot.quantity = 0
		
	inventory_updated.emit()
	return true

func _find_first_empty_slot() -> InventorySlot:
	for slot in slots:
		if slot.item_data == null:
			return slot
	return null
