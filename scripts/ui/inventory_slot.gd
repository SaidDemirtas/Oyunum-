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
	if slot_data != null and icon != null:
		icon.texture = slot_data.icon
	elif icon != null:
		icon.texture = null

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
	preview.texture = slot_data.icon
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
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("source") and data["source"] == "inventory_slot"

# Sürüklenen eşyayı bırak ve takas et
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_slot = data["slot_node"]
	var temp_data = slot_data
	
	# Hedef ile Kaynak arasında takas yap
	slot_data = source_slot.slot_data
	source_slot.slot_data = temp_data
