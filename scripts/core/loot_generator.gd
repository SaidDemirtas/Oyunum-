extends Node

# Bir eşya düştüğünde çağrılacak ana fonksiyon
func generate_item_with_cards(base_item: ItemData) -> ItemData:
	# 1. Eşyanın benzersiz bir kopyasını oluştur (Orijinal dosyayı bozmamak için)
	var new_item = base_item.duplicate(true)
	
	# Olası eski kartları temizle (ne olur ne olmaz)
	new_item.card_pool.clear()
	
	# 2. Eşyanın nadirliğine göre kaç kart alacağını belirle
	var card_count: int = 0
	match new_item.rarity:
		ItemData.ItemRarity.COMMON: card_count = 0     # Yaygın eşyada kart yok (veya 1 yapabilirsin)
		ItemData.ItemRarity.RARE: card_count = 1       # Nadir eşyada 1 kart
		ItemData.ItemRarity.EPIC: card_count = 2       # Epik eşyada 2 kart
		ItemData.ItemRarity.MYSTIC: card_count = 3     # Gizemli eşyada 3 kart
		ItemData.ItemRarity.LEGENDARY: card_count = 4  # Efsanevi eşyada 4 kart
		
	if card_count == 0:
		return new_item # Kart eklenmeyecekse direkt geri döndür
		
	# 3. Eşyanın türüne göre doğru kart havuzunu (desteyi) seç
	var target_pool: Array[CardData] = []
	match new_item.slot_type:
		ItemData.EquipmentSlot.WEAPON:
			target_pool = CardDatabase.weapon_cards
		ItemData.EquipmentSlot.ARMOR, ItemData.EquipmentSlot.HELMET:
			target_pool = CardDatabase.armor_cards
		ItemData.EquipmentSlot.NECKLACE, ItemData.EquipmentSlot.BOOTS:
			target_pool = CardDatabase.utility_cards
			
	# Havuz boşsa hata vermemesi için güvenlik kontrolü
	if target_pool.size() == 0:
		print("Uyarı: Bu eşya türü için havuzda hiç kart yok!")
		return new_item
		
	# 4. Havuzdan rastgele kartları seçip eşyaya ekle
	for i in range(card_count):
		# target_pool içinden rastgele bir kart seç (.pick_random() Godot 4'ün harika bir özelliğidir)
		var random_card = target_pool.pick_random()
		
		# Aynı kartın iki kere gelmesini istemiyorsan buraya bir if kontrolü eklenebilir, 
		# şimdilik aynı yetenekten 2 tane gelebilmesine izin veriyoruz.
		new_item.card_pool.append(random_card)
		
	return new_item
