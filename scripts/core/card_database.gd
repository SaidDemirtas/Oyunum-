extends Node

# Oyun boyunca kartları tutacağımız ana havuzlar
var weapon_cards: Array[CardData] = []
var armor_cards: Array[CardData] = []
var utility_cards: Array[CardData] = []

func _ready():
	# Oyun başlar başlamaz klasörleri taramaya başlıyoruz
	load_cards_from_directory("res://data/cards/weapon_cards/", weapon_cards)
	load_cards_from_directory("res://data/cards/armor_cards/", armor_cards)
	load_cards_from_directory("res://data/cards/utility_cards/", utility_cards)
	
	# Test için konsola bilgi yazdır
	print("--- KART VERİTABANI YÜKLENDİ ---")
	print("Silah Kartları: ", weapon_cards.size(), " adet")
	print("Zırh Kartları: ", armor_cards.size(), " adet")
	print("Yardımcı Kartlar: ", utility_cards.size(), " adet")

# Klasördeki dosyaları okuyup dizilere aktaran motor
func load_cards_from_directory(path: String, target_array: Array[CardData]):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Klasör değilse ve sonu .tres ile bitiyorsa
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				# Kartı hafızaya yükle
				var card = load(path + file_name) as CardData
				if card:
					target_array.append(card)
			
			file_name = dir.get_next()
	else:
		print("UYARI: Klasör bulunamadı - ", path)
