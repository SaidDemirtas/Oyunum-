class_name InventoryUI
extends Control
## ENVANTER EKRANI
## Eşyaları PlayerData'dan okur, her değişiklikte PlayerData'ya geri yazar.
## "Savaşa Gir" düğmesi (sahnede %FightButton) savaş sahnesini açar.

const COMBAT_SCENE := "res://scenes/combat_scene.tscn"

@onready var info_panel = $MainLayout/StoragePanel/ItemInfoPanel
@onready var name_label = $MainLayout/StoragePanel/ItemInfoPanel/VBoxContainer/NameLabel
@onready var rarity_label = $MainLayout/StoragePanel/ItemInfoPanel/VBoxContainer/RarityLabel
@onready var desc_label = $MainLayout/StoragePanel/ItemInfoPanel/VBoxContainer/DescLabel

## Artık kullanılmıyor (eşyalar PlayerData'dan geliyor). Sahne bozulmasın diye duruyor.
@export var test_item: Resource
@export var slot_scene: PackedScene
@onready var inventory_grid: GridContainer = $MainLayout/StoragePanel/ScrollContainer/InventoryGrid

# Ekipman Yuvaları
@onready var equipment_slots = [
	$MainLayout/EquipmentPanel/WeaponSlot,
	$MainLayout/EquipmentPanel/ArmorSlot,
	$MainLayout/EquipmentPanel/HelmetSlot,
	$MainLayout/EquipmentPanel/NecklaceSlot,
	$MainLayout/EquipmentPanel/BootsSlot
]

# Stat Etiketleri
# DÜZELTME: StatsPanel sahnede MainLayout'un altında, EquipmentPanel'in değil.
# Eski yollar yanlış olduğu için statlar hiç görünmüyordu.
@onready var str_label = get_node_or_null("MainLayout/StatsPanel/StrLabel")
@onready var hp_label = get_node_or_null("MainLayout/StatsPanel/HpLabel")
@onready var shield_label = get_node_or_null("MainLayout/StatsPanel/ShieldLabel")
@onready var crit_chance_label = get_node_or_null("MainLayout/StatsPanel/CritChanceLabel")
@onready var crit_damage_label = get_node_or_null("MainLayout/StatsPanel/CritDamageLabel")
@onready var lifesteal_label = get_node_or_null("MainLayout/StatsPanel/LifestealLabel")
@onready var stun_label = get_node_or_null("MainLayout/StatsPanel/StunLabel")
@onready var strength_buff_label = get_node_or_null("MainLayout/StatsPanel/StrengthBuffLabel")
@onready var vulnerability_label = get_node_or_null("MainLayout/StatsPanel/VulnerabilityLabel")
@onready var weaken_label = get_node_or_null("MainLayout/StatsPanel/WeakenLabel")

## Sahnede yoksa hata vermez; eklenince otomatik çalışır.
@onready var fight_button: Button = get_node_or_null("%FightButton")

# Çanta kutuları (sırası PlayerData.bag ile aynı)
var bag_slots: Array = []

# Taşıma (Sanal El) Değişkenleri
var dragged_item: ItemData = null
var dragged_source_slot = null
var drag_preview: TextureRect


func _ready():
	add_to_group("inventory_ui")
	hide_item_info()
	_generate_inventory_slots(PlayerData.BAG_SIZE)
	_load_from_player_data()

	# Fareye yapışacak hayali ikonu oluştur
	drag_preview = TextureRect.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 100
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.custom_minimum_size = Vector2(40, 40)
	add_child(drag_preview)

	if fight_button != null:
		fight_button.pressed.connect(_on_fight_pressed)

	calculate_total_stats()


func _process(_delta):
	if dragged_item != null:
		drag_preview.global_position = get_global_mouse_position() + Vector2(10, 10)


# ---------------------------------------------------------------
# PLAYERDATA İLE SENKRONİZASYON
# ---------------------------------------------------------------

## PlayerData'daki eşyaları kutulara yerleştirir (ekran açılınca).
func _load_from_player_data() -> void:
	for i in bag_slots.size():
		bag_slots[i].slot_data = PlayerData.bag[i]
	for slot in equipment_slots:
		if slot != null:
			slot.slot_data = PlayerData.equipped.get(slot.allowed_slot_type)


## Kutulardaki güncel durumu PlayerData'ya yazar.
func _save_to_player_data() -> void:
	for i in bag_slots.size():
		PlayerData.bag[i] = bag_slots[i].slot_data
	for slot in equipment_slots:
		if slot != null:
			PlayerData.equipped[slot.allowed_slot_type] = slot.slot_data
	PlayerData.data_changed.emit()


## Bir eşya yer değiştirdiğinde çağrılır (tıklama veya sürükle-bırak).
func on_inventory_changed() -> void:
	_save_to_player_data()
	calculate_total_stats()


# ---------------------------------------------------------------
# SAVAŞA GİRİŞ
# ---------------------------------------------------------------
func _on_fight_pressed() -> void:
	if is_dragging():
		print("Önce elindeki eşyayı bir kutuya bırak.")
		return
	if not PlayerData.has_any_equipped_cards():
		print("Takılı eşyalarda hiç kart yok, savaşa girilemez.")
		return
	get_tree().change_scene_to_file(COMBAT_SCENE)


# ---------------------------------------------------------------
# TAŞIMA (METİN2 SİSTEMİ)
# ---------------------------------------------------------------
func is_dragging() -> bool:
	return dragged_item != null


func pick_item(slot):
	dragged_item = slot.slot_data
	dragged_source_slot = slot
	drag_preview.texture = slot.icon.texture # (ikonsuz eşyada geçici ikon da görünsün)
	slot.slot_data = null
	calculate_total_stats()


func drop_item(target_slot):
	if target_slot == dragged_source_slot:
		target_slot.slot_data = dragged_item
	else:
		var temp_data = target_slot.slot_data
		target_slot.slot_data = dragged_item
		dragged_source_slot.slot_data = temp_data

	dragged_item = null
	dragged_source_slot = null
	drag_preview.texture = null

	on_inventory_changed()


func show_item_info(item: ItemData):
	name_label.text = item.item_name
	rarity_label.text = str(ItemData.ItemRarity.keys()[item.rarity])
	var card_names: PackedStringArray = []
	for card in item.card_pool:
		if card != null:
			card_names.append(card.card_name)
	var cards_text := "Kartlar: " + (", ".join(card_names) if not card_names.is_empty() else "yok")
	desc_label.text = item.item_description + "\n" + cards_text


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
		bag_slots.append(new_slot)


# ---------------------------------------------------------------
# STAT HESAPLAMA VE GÖSTERİM
# ---------------------------------------------------------------
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

	for slot in equipment_slots:
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
