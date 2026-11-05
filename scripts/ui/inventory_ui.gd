class_name InventoryUI
extends Control

@onready var info_panel = $MainLayout/StoragePanel/ItemInfoPanel
@onready var name_label = $MainLayout/StoragePanel/ItemInfoPanel/VBoxContainer/NameLabel
@onready var rarity_label = $MainLayout/StoragePanel/ItemInfoPanel/VBoxContainer/RarityLabel
@onready var desc_label = $MainLayout/StoragePanel/ItemInfoPanel/VBoxContainer/DescLabel

@export var test_item: Resource
@export var slot_scene: PackedScene
@onready var inventory_grid: GridContainer = $MainLayout/StoragePanel/ScrollContainer/InventoryGrid

# Ekipman Yuvaları (Ağaç yapına göre yolları kontrol etmeyi unutma)
@onready var equipment_slots = [
	$MainLayout/EquipmentPanel/WeaponSlot,
	$MainLayout/EquipmentPanel/ArmorSlot,
	$MainLayout/EquipmentPanel/HelmetSlot,
	$MainLayout/EquipmentPanel/NecklaceSlot,
	$MainLayout/EquipmentPanel/BootsSlot
]

# Stat Etiketleri (Labellar)
@onready var str_label = $MainLayout/EquipmentPanel/StatsPanel/StrLabel
@onready var hp_label = $MainLayout/EquipmentPanel/StatsPanel/HpLabel
@onready var shield_label = $MainLayout/EquipmentPanel/StatsPanel/ShieldLabel
@onready var crit_chance_label = $MainLayout/EquipmentPanel/StatsPanel/CritChanceLabel
@onready var crit_damage_label = $MainLayout/EquipmentPanel/StatsPanel/CritDamageLabel
@onready var lifesteal_label = $MainLayout/EquipmentPanel/StatsPanel/LifestealLabel
@onready var stun_label = $MainLayout/EquipmentPanel/StatsPanel/StunLabel
@onready var strength_buff_label = $MainLayout/EquipmentPanel/StatsPanel/StrengthBuffLabel
@onready var vulnerability_label = $MainLayout/EquipmentPanel/StatsPanel/VulnerabilityLabel
@onready var weaken_label = $MainLayout/EquipmentPanel/StatsPanel/WeakenLabel

# Taşıma (Sanal El) Değişkenleri
var dragged_item: ItemData = null
var dragged_source_slot = null
var drag_preview: TextureRect

func _ready():
	add_to_group("inventory_ui")
	hide_item_info()
	_generate_inventory_slots(20)
	
	# Fareye yapışacak hayali ikonu oluştur
	drag_preview = TextureRect.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE # Tıklamaları engellememesi için çok önemli!
	drag_preview.z_index = 100
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.custom_minimum_size = Vector2(40, 40)
	add_child(drag_preview)
	
	# Oyun başlarken statları bir kez hesapla
	calculate_total_stats()

func _process(_delta):
	# Elimizde eşya varsa ikon fareyi sürekli takip etsin
	if dragged_item != null:
		drag_preview.global_position = get_global_mouse_position() + Vector2(10, 10)

func is_dragging() -> bool:
	return dragged_item != null

func pick_item(slot):
	dragged_item = slot.slot_data
	dragged_source_slot = slot
	drag_preview.texture = dragged_item.icon
	
	slot.slot_data = null # Kutuyu boşalt
	
	# Eşya elinize alındığında statları hemen güncellemek isterseniz (isteğe bağlı)
	calculate_total_stats()

func drop_item(target_slot):
	# Eğer eşyayı aldığımız kutuya tekrar bırakıyorsak takas yapma, direkt geri koy
	if target_slot == dragged_source_slot:
		target_slot.slot_data = dragged_item
	else:
		# Farklı bir kutuya bırakılıyorsa normal takas (swap) işlemini yap
		var temp_data = target_slot.slot_data
		target_slot.slot_data = dragged_item
		dragged_source_slot.slot_data = temp_data
		
	# Fareyi (Eli) temizle
	dragged_item = null
	dragged_source_slot = null
	drag_preview.texture = null
	
	# Eşya yeni yerine yerleştiğinde statları yeniden hesapla
	calculate_total_stats()

func show_item_info(item: ItemData):
	name_label.text = item.item_name
	rarity_label.text = str(ItemData.ItemRarity.keys()[item.rarity])
	desc_label.text = item.item_description

func hide_item_info():
	name_label.text = ""
	rarity_label.text = ""
	desc_label.text = ""

func _generate_inventory_slots(amount: int) -> void:
	if slot_scene == null:
		print("Hata: Slot Scene atanmamış!")
		return
		
	for i in range(amount):
		var new_slot = slot_scene.instantiate()
		inventory_grid.add_child(new_slot)
		
		# Test eşyasını ilk kutuya koy
		if i == 0:
			new_slot.slot_data = test_item

# --- STAT HESAPLAMA VE GÖSTERİM SİSTEMİ ---

func calculate_total_stats():
	var total_str: int = 0
	var total_hp: int = 0
	var total_shield: int = 0
	var total_crit_chance: float = 0.0
	var total_crit_dmg: float = 0.0
	var total_lifesteal: float = 0.0
	var total_stun: float = 0.0
	var total_str_buff: float = 0.0
	var total_vuln: float = 0.0
	var total_weaken: float = 0.0
	
	# Tüm takılı eşyaları tara ve değerleri topla
	for slot in equipment_slots:
		# Senin taşıma sisteminde eşya verisi "slot_data" olarak tanımlanmış
		if slot != null and slot.slot_data != null:
			total_str += slot.slot_data.str_damage
			total_hp += slot.slot_data.bonus_max_hp
			total_shield += slot.slot_data.shield
			total_crit_chance += slot.slot_data.crit_chance
			total_crit_dmg += slot.slot_data.crit_damage_modifier
			total_lifesteal += slot.slot_data.lifesteal
			total_stun += slot.slot_data.stun_chance
			total_str_buff += slot.slot_data.strength_buff
			total_vuln += slot.slot_data.vulnerability
			total_weaken += slot.slot_data.weaken
			
	# Yardımcı fonksiyon ile etiketleri güncelle ve gizle/göster
	update_stat_label(str_label, "STR (Hasar): ", total_str)
	update_stat_label(hp_label, "Ekstra Can: +", total_hp)
	update_stat_label(shield_label, "Tur Kalkanı: ", total_shield)
	update_stat_label(crit_chance_label, "Kritik Şansı: %", total_crit_chance * 100)
	update_stat_label(crit_damage_label, "Kritik Hasarı: +%", total_crit_dmg * 100)
	update_stat_label(lifesteal_label, "Can Çalma: %", total_lifesteal * 100)
	update_stat_label(stun_label, "Sersemletme Şansı: %", total_stun * 100)
	update_stat_label(strength_buff_label, "Kuvvet Buff'ı: %", total_str_buff * 100)
	update_stat_label(vulnerability_label, "Kırılganlık: %", total_vuln * 100)
	update_stat_label(weaken_label, "Zayıflatma: %", total_weaken * 100)

func update_stat_label(label: Label, prefix: String, value: float):
	if label == null:
		return
		
	if value > 0:
		label.text = prefix + str(value)
		label.show() 
	else:
		label.hide()
