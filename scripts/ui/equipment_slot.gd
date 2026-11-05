class_name UIEquipmentSlot
extends UIInventorySlot # Bütün sürükle-bırak özelliklerini normal yuvadan miras alır

@export var allowed_slot_type: ItemData.EquipmentSlot # Inspector'dan bu yuvanın türünü seçeceğiz

# Bırakma onayını eziyoruz (Override)
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("source") and data["source"] == "inventory_slot":
		var item = data["item_data"]
		
		# Sürüklenen eşya varsa ve türü yuvanın izin verdiği türle eşleşiyorsa kabul et
		if item != null and item.slot_type == allowed_slot_type:
			return true
		# Sürüklenen şey boş bir yuvaysa (eşyayı geri alıyorsak) kabul et
		elif item == null:
			return true
			
	return false
