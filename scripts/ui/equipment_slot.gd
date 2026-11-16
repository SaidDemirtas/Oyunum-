class_name UIEquipmentSlot
extends UIInventorySlot # Bütün sürükle-bırak özelliklerini normal yuvadan miras alır

@export var allowed_slot_type: ItemData.EquipmentSlot # Inspector'dan bu yuvanın türünü seçeceğiz

# Bu yuva sadece kendi türündeki eşyayı kabul eder.
# Hem tıklama (Metin2) hem sürükle-bırak sistemi bu kontrolü kullanır,
# bu yüzden ayrı bir _can_drop_data yazmaya gerek kalmadı.
# (Eskiden "category" alanına bakılıyordu; LootGenerator'ın ürettiği eşyalarda
#  category boş kaldığı için takılamıyorlardı. Artık slot_type esas alınıyor.)
func can_accept_item(item: ItemData) -> bool:
	if item == null:
		return true
	return item.slot_type == allowed_slot_type
