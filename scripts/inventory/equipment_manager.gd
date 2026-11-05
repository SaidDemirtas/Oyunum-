class_name EquipmentManager
extends Node

signal equipment_changed(slot: ItemData.EquipmentSlot, item: ItemData)

# 5 ana ekipman slotunu tutan sözlük:
var equipped_items: Dictionary = {
	ItemData.EquipmentSlot.HELMET: null,
	ItemData.EquipmentSlot.ARMOR: null,
	ItemData.EquipmentSlot.WEAPON: null,
	ItemData.EquipmentSlot.NECKLACE: null,
	ItemData.EquipmentSlot.BOOTS: null
}

@export var player_stats: PlayerStats

# Eşya Kuşanma
func equip_item(item: ItemData) -> ItemData:
	if item == null:
		return null
		
	var target_slot = item.slot_type
	var previous_item: ItemData = equipped_items[target_slot]
	
	# Eğer o slotta zaten bir eşya varsa önce onu çıkarıp statlarını sil
	if previous_item != null:
		_remove_item_stats(previous_item)
		
	equipped_items[target_slot] = item
	_apply_item_stats(item)
	equipment_changed.emit(target_slot, item)
	
	return previous_item # Çantaya geri dönmesi için eski itemi döner

# Eşya Çıkarma
func unequip_item(slot: ItemData.EquipmentSlot) -> ItemData:
	var item: ItemData = equipped_items[slot]
	if item != null:
		_remove_item_stats(item)
		equipped_items[slot] = null
		equipment_changed.emit(slot, null)
	return item

# Kuşanılmış 5 eşyanın kart havuzlarını toplar
func get_equipped_card_pools() -> Dictionary:
	var pools: Dictionary = {}
	for slot in equipped_items.keys():
		var item: ItemData = equipped_items[slot]
		if item != null:
			pools[slot] = item.card_pool
		else:
			pools[slot] = []
	return pools

# Stat Güncellemeleri
func _apply_item_stats(item: ItemData) -> void:
	if player_stats == null:
		return
	if item.bonus_max_hp > 0:
		var current = player_stats.modifier_stats.get(PlayerStats.StatType.MAX_HP, 0)
		player_stats.modifier_stats[PlayerStats.StatType.MAX_HP] = current + item.bonus_max_hp
		player_stats.stats_changed.emit()

func _remove_item_stats(item: ItemData) -> void:
	if player_stats == null:
		return
	if item.bonus_max_hp > 0:
		var current = player_stats.modifier_stats.get(PlayerStats.StatType.MAX_HP, 0)
		player_stats.modifier_stats[PlayerStats.StatType.MAX_HP] = max(0, current - item.bonus_max_hp)
		player_stats.stats_changed.emit()
