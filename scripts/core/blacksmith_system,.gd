class_name BlacksmithSystem
extends Node

signal evolution_succeeded(old_item: ItemData, evolved_item: ItemData)
signal item_destroyed(destroyed_item: ItemData)

# Eşyanın mevcut nadirliğine göre bir üst nadirliğe evrilme şansı:
const EVOLUTION_CHANCES = {
	ItemData.ItemRarity.COMMON: 0.80,    # Yaygın -> Nadir: %80
	ItemData.ItemRarity.RARE: 0.60,      # Nadir -> Epik: %60
	ItemData.ItemRarity.EPIC: 0.40,      # Epik -> Gizemli: %40
	ItemData.ItemRarity.MYSTIC: 0.20,    # Gizemli -> Efsanevi: %20
	ItemData.ItemRarity.LEGENDARY: 0.0   # Efsanevi daha fazla evrilemez
}

# Eşyayı bir üst nadirlikteki yeni eşyaya dönüştürmeyi dener
func evolve_item(item: ItemData, catalyst: ConsumableData = null) -> ItemData:
	if item == null:
		return null
		
	# Efsanevi eşya veya evrileceği yeni eşya tanımlanmamışsa işlem yapılmaz
	if item.rarity == ItemData.ItemRarity.LEGENDARY or item.upgraded_version == null:
		return item
		
	var chance: float = EVOLUTION_CHANCES.get(item.rarity, 0.5)
	
	# Eğer efsun taşı/katalizör kullanıldıysa başarı şansını artır
	if catalyst != null:
		chance *= catalyst.success_rate
		
	var roll: float = randf() # 0.0 - 1.0 arası rastgele sayı
	
	if roll <= chance:
		# BAŞARILI: Eski eşya biter, yeni üst nadirlik eşyası gelir
		var evolved_item: ItemData = item.upgraded_version
		evolution_succeeded.emit(item, evolved_item)
		return evolved_item
	else:
		# BAŞARISIZ: Eşya yandı, tamamen silindi
		item_destroyed.emit(item)
		return null
