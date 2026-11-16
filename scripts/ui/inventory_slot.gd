class_name UIInventorySlot
extends PanelContainer


enum SlotType { GENERAL, WEAPON, HELMET, ARMOR, BOOTS, NECKLACE }
@export var slot_type: SlotType = SlotType.GENERAL

# Gelen eşyanın bu yuvaya uygun olup olmadığını denetleyen motor
func can_accept_item(item: ItemData) -> bool:
	if item == null:
		return true # Boşluğu her yuva kabul eder
	if slot_type == SlotType.GENERAL:
		return true # Çanta yuvaları (General) her eşyayı kabul eder
		
	# Yuva türü ile eşya türü numarası aynıysa kabul et (Örn: Weapon == Weapon)
	return int(slot_type) == int(item.category)


@onready var icon: TextureRect = $Icon

var slot_data = null :
	set(value):
		slot_data = value
		if is_node_ready():
			_update_visuals()

func _ready():
	_update_visuals()

func _update_visuals():
	self_modulate = Color(1, 1, 1, 1)
	if icon == null:
		return
	if slot_data == null:
		icon.texture = null
		tooltip_text = ""
		return
	# İkonu olmayan eşya görünmez kalmasın: nadirlik renginde bir kare göster
	icon.texture = slot_data.icon if slot_data.icon != null else get_placeholder_icon(slot_data.rarity)
	# Fareyle üstüne gelince eşyanın adı görünsün
	tooltip_text = slot_data.item_name


# --- İKONSUZ EŞYALAR İÇİN GEÇİCİ İKON ---
# Sıra: Common, Rare, Epic, Mystic, Legendary
const RARITY_COLORS := [
	Color(0.55, 0.55, 0.55),  # Yaygın: gri
	Color(0.25, 0.5, 1.0),    # Nadir: mavi
	Color(0.65, 0.3, 0.9),    # Epik: mor
	Color(0.1, 0.8, 0.75),    # Gizemli: turkuaz
	Color(1.0, 0.6, 0.1)      # Efsanevi: turuncu
]
static var _placeholder_cache: Dictionary = {}

static func get_placeholder_icon(rarity: int) -> Texture2D:
	if _placeholder_cache.has(rarity):
		return _placeholder_cache[rarity]
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)])
	var tex := ImageTexture.create_from_image(img)
	_placeholder_cache[rarity] = tex
	return tex

# --- 1. METİN2 SİSTEMİ (Çift Tıkla Al, Tek Tıkla Bırak) ---
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
		if inv_ui == null:
			return
			
		# A. ELİMİZDE EŞYA VARSA -> Tek tıkla bırak (veya takas et)
		if inv_ui.is_dragging():
			var dragged_item = inv_ui.dragged_item
			var source_slot = inv_ui.dragged_source_slot
			var target_item = self.slot_data
			
			# Çift taraflı güvenlik duvarı:
			if self.can_accept_item(dragged_item) and source_slot.can_accept_item(target_item):
				inv_ui.drop_item(self)
			else:
				print("HATA: Bu eşya bu yuvaya yerleştirilemez!")
			return
			
		# B. Elimde eşya yoksa -> Çift tıkla AL (Fareye yapıştır)
		if event.double_click:
			if slot_data != null:
				inv_ui.pick_item(self)
				inv_ui.hide_item_info()
				
		# C. Elimde eşya yoksa -> Tek tıkla BİLGİ GÖSTER
		else:
			if slot_data != null:
				inv_ui.show_item_info(slot_data)
			else:
				inv_ui.hide_item_info()

# --- 2. KLASİK SİSTEM (Basılı Tut ve Sürükle) ---
func _get_drag_data(_at_position: Vector2) -> Variant:
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	
	# Eğer elimizde zaten "çift tıklama" ile alınmış yapışkan eşya varsa sürüklemeyi iptal et
	if inv_ui.is_dragging() or slot_data == null:
		return null
		
	# Farenin ucuna yarı saydam resmi tak
	var preview = TextureRect.new()
	preview.texture = icon.texture # (ikonsuz eşyada geçici ikon da görünsün)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = size
	
	var preview_control = Control.new()
	preview.position = -size / 2 
	preview_control.add_child(preview)
	set_drag_preview(preview_control)
	
	return {
		"source": "inventory_slot",
		"slot_node": self,
		"item_data": slot_data # Ekipman slotlarının çökmemesi için eklendi
	}

# Sürüklenen eşyanın kutuya girmesine izin ver
# Takasın iki yönü de kontrol edilir: gelen eşya buraya uyuyor mu,
# buradaki eşya da kaynağa (örneğin bir ekipman yuvasına) uyuyor mu?
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (typeof(data) == TYPE_DICTIONARY and data.has("source") and data["source"] == "inventory_slot"):
		return false
	var source_slot = data["slot_node"]
	return can_accept_item(data["item_data"]) and source_slot.can_accept_item(slot_data)

# Sürüklenen eşyayı bırak ve takas et
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_slot = data["slot_node"]
	var temp_data = slot_data

	# Hedef ile Kaynak arasında takas yap
	slot_data = source_slot.slot_data
	source_slot.slot_data = temp_data

	# Değişikliği envantere bildir (PlayerData ve stat paneli güncellensin)
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui != null:
		inv_ui.on_inventory_changed()
