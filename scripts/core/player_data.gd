extends Node
## PLAYER DATA (Autoload adı: PlayerData)
## Oyuncunun sahneler arasında kaybolmayan verisi burada durur:
## takılı eşyalar, çanta, can ve altın.
## Envanter ekranı buraya yazar, savaş ekranı buradan okur.

signal data_changed

const BAG_SIZE := 20
## Test için: bu klasördeki (ve alt klasörlerindeki) tüm eşyalar oyun başında çantaya konur.
const TEST_ITEMS_FOLDER := "res://data/items/"

## ItemData.EquipmentSlot -> ItemData (boş slot = null)
var equipped: Dictionary = {}
## BAG_SIZE uzunluğunda dizi, boş kutular null
var bag: Array = []
## -1 = bir sonraki savaşa tam canla gir
var current_hp: int = -1
var gold: int = 0


func _ready() -> void:
	start_new_run()


## Yeni bir oyun başlatır: her şeyi sıfırlar ve test eşyalarını çantaya koyar.
func start_new_run() -> void:
	equipped.clear()
	for slot in ItemData.EquipmentSlot.values():
		equipped[slot] = null

	bag.clear()
	bag.resize(BAG_SIZE)

	current_hp = -1
	gold = 0

	_give_test_items()
	data_changed.emit()


# ---------------------------------------------------------------
# EŞYA İŞLEMLERİ
# ---------------------------------------------------------------

## Bir eşya şablonunu oyuncuya ait benzersiz bir kopyaya çevirir.
## Kart havuzu boşsa LootGenerator nadirliğe göre kart atar.
func prepare_item(base: ItemData) -> ItemData:
	var item := base.duplicate(true) as ItemData

	# Boş (null) kart yuvalarını temizle
	var clean_cards: Array[CardData] = []
	for card in item.card_pool:
		if card != null:
			clean_cards.append(card)
	item.card_pool = clean_cards

	if item.card_pool.is_empty():
		item = LootGenerator.generate_item_with_cards(item)
	return item


## Çantadaki ilk boş kutuya eşya koyar. Çanta doluysa false döner.
func add_to_bag(item: ItemData) -> bool:
	for i in bag.size():
		if bag[i] == null:
			bag[i] = item
			data_changed.emit()
			return true
	print("Çanta dolu, eşya eklenemedi: ", item.item_name)
	return false


## En az bir takılı eşyada kart var mı?
func has_any_equipped_cards() -> bool:
	for item in equipped.values():
		if item != null and not item.card_pool.is_empty():
			return true
	return false


# ---------------------------------------------------------------
# TEST EŞYALARI
# ---------------------------------------------------------------
func _give_test_items() -> void:
	for path in _find_item_files(TEST_ITEMS_FOLDER):
		var base := load(path) as ItemData
		if base != null:
			add_to_bag(prepare_item(base))


## Klasörü alt klasörleriyle birlikte tarar, .tres dosyalarının yollarını döndürür.
func _find_item_files(folder: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir := DirAccess.open(folder)
	if dir == null:
		print("UYARI: Eşya klasörü bulunamadı - ", folder)
		return result

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := folder.path_join(file_name)
		if dir.current_is_dir():
			result.append_array(_find_item_files(full_path))
		else:
			# Dışa aktarılmış oyunda dosyalar ".tres.remap" olarak görünür
			if file_name.ends_with(".remap"):
				full_path = full_path.trim_suffix(".remap")
			if full_path.ends_with(".tres"):
				result.append(full_path)
		file_name = dir.get_next()

	result.sort()
	return result
